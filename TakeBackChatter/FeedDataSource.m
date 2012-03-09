//
//  FeedDataSource.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedDataSource.h"
#import "zkSforce.h"
#import "FeedItem.h"
#import "FeedPage.h"
#import "NSDate_iso8601.h"
#import "NSArray_extras.h"
#import "NSData-Base64Extensions.h"
#import "TakeBackChatterAppDelegate.h"
#import "UrlConnectionDelegate.h"
#import "prefs.h"
#import "NSString-Base64Extensions.h"

@interface FeedDataSource ()

@property (assign) BOOL hasMore;
@property (nonatomic,retain) NSArray *feedItems;
@property (nonatomic,retain) NSArray *filteredFeedItems;
@property (nonatomic,retain) NSArray *junkFeedItems;

-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore;

@end

@implementation FeedDataSource

@synthesize sforce, hasMore;
@synthesize feedItems, filteredFeedItems, junkFeedItems;

// This tells KVO (and theirfore the UI binding), that the 'junkCount' property value is affected by changes to the 'junkFeedItems' property
// We only have the junkCount property because it doesn't appear possible to bind to the count property of NSArray (which seems odd)
+(NSSet *)keyPathsForValuesAffectingJunkCount {
    return [NSSet setWithObject:@"junkFeedItems"];
}

-(id)initWithSforceClient:(ZKSforceClient *)c {
    self = [super init];
    sforce = [c retain];
    feedPages = [[NSMutableArray alloc] init];
    return self;
}

-(NSArray *)feedPages {
    return feedPages;
}

-(NSURL *)serverUrl {
    return sforce.serverUrl;
}

-(NSString *)sessionId {
    return sforce.sessionId;
}

-(NSArray *)resolveNewFeed:(FeedPage *)newFrontPage {
    if ([feedPages count] > 0) {
        // the set of feed Item Ids in the current front page.
        NSMutableSet *fp = [[[NSMutableSet alloc] init] autorelease];
        for (FeedItem *i in [[feedPages objectAtIndex:0] feedItems]) {
            [fp addObject:[i rowId]];
        }
        NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:[[newFrontPage feedItems] count]];
        for (FeedItem *i in [newFrontPage feedItems]) {
            if ([fp containsObject:[i rowId]]) break;
            [newItems addObject:i];
        }
        // nothing new to add, just return the current feed.
        if ([newItems count] == 0)
            return self.feedItems;
        // got at least one new item, add the page, and build the new feed items list.
        [feedPages insertObject:newFrontPage atIndex:0];
        return [newItems arrayByAddingObjectsFromArray:self.feedItems];
        
    } else {
        [feedPages insertObject:newFrontPage atIndex:0];
        return [newFrontPage feedItems];
    }
}

-(void)fetchJsonUrl:(NSURL *)url done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:[NSString stringWithFormat:@"OAuth %@", self.sessionId] forHTTPHeaderField:@"Authorization"];
    JsonUrlConnectionDelegateWithBlock *delegate = [JsonUrlConnectionDelegateWithBlock
                                                    urlDelegateWithBlock:doneBlock runOnMainThread:runOnMain];

    NSLog(@"starting request for %@ %@", [req HTTPMethod], [req URL]);
    [[[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES] autorelease];
}

-(void)fetchJsonPath:(NSString *)path done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain {
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.serverUrl];
    [self fetchJsonUrl:url done:doneBlock runOnMainThread:runOnMain];
}

-(void)fetchFeed:(NSURL *)feedUrl newer:(BOOL)newer {
    [self fetchJsonUrl:feedUrl done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        if (httpStatusCode == 200) {
            FeedPage *page = [FeedPage connectFeedPage:(NSDictionary *)jsonValue dataSource:self];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSArray *newFeed;
                if (newer) {
                    newFeed = [self resolveNewFeed:page];
                } else {
                    [feedPages addObject:page];
                    newFeed = [self.feedItems arrayByAddingObjectsFromArray:[page feedItems]];
                }
                
                [self setFeedItems:newFeed updateHasMore:YES];
                self.feedItems = newFeed;
            });
            
        } else {
            NSLog(@"Feed request returned HTTP status code %lu", httpStatusCode);
        }
    } runOnMainThread:YES];
}

-(IBAction)loadNewerRows:(id)sender {
    NSURL *feedUrl = [NSURL URLWithString:@"/services/data/v24.0/chatter/feeds/news/me/feed-items?sort=LastModifiedDateDesc" 
                            relativeToURL:[self.sforce serverUrl]];
    [self fetchFeed:feedUrl newer:YES];
}

-(IBAction)loadOlderRows:(id)sender {
    NSURL *feedUrl = [[feedPages lastObject] nextUrl];
    [self fetchFeed:feedUrl newer:NO];
}

-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore {
    if (updateMore)
        self.hasMore = [[feedPages lastObject] nextUrl] != nil;
    self.feedItems = items;
    [self filterFeed];
}

-(void)filterFeed {
    NSNumber *junkThreshold = [NSNumber numberWithLong:[[NSUserDefaults standardUserDefaults] integerForKey:PREFS_JUNK_THRESHOLD]];
    NSPredicate *junkp = [NSPredicate predicateWithFormat:@"chanceIsJunk > %@", junkThreshold];
    NSArray *junk = [feedItems filteredArrayUsingPredicate:junkp];
    NSPredicate *goodp = [NSPredicate predicateWithFormat:@"chanceIsJunk <= %@", junkThreshold];
    NSArray *filtered = [feedItems filteredArrayUsingPredicate:goodp];
    self.junkFeedItems = junk;
    self.filteredFeedItems = filtered;
}

-(NSUInteger)junkCount {
    return self.junkFeedItems.count;
}

-(void)checkSaveResult:(ZKSaveResult *)sr {
    if ([sr success]) {
        [self loadNewerRows:self];
    } else {
        NSLog(@"%@ %@", [sr statusCode], [sr message]);
    }
}

-(void)updateStatus:(NSString *)newStatus {
    ZKSObject *user = [ZKSObject withTypeAndId:@"User" sfId:[[self.sforce currentUserInfo] userId]];
    [user setFieldValue:newStatus field:@"CurrentStatus"];
    ZKSaveResult *sr = [[self.sforce update:[NSArray arrayWithObject:user]] firstObject];
    [self checkSaveResult:sr];
}

-(void)createContentPost:(NSString *)postText content:(NSData *)content contentName:(NSString *)name {
    ZKSObject *post = [ZKSObject withType:@"FeedPost"];
    [post setFieldValue:name field:@"ContentFileName"];
    [post setFieldValue:[content encodeBase64] field:@"ContentData"];
    [post setFieldValue:[[self.sforce currentUserInfo] userId] field:@"ParentId"];
    [post setFieldValue:postText field:@"Body"];
    ZKSaveResult *sr = [[self.sforce create:[NSArray arrayWithObject:post]] firstObject];
    [self checkSaveResult:sr];
}

-(NSString *)defaultWindowTitle {
    return [NSString stringWithFormat:@"%@ / %@", [[self.sforce currentUserInfo] userName], [[self.sforce serverUrl] host]];
}

-(NSString *)defaultWindowAutosaveName {
    return [NSString stringWithFormat:@"%@ / %@", [[self.sforce currentUserInfo] userId], [[self.sforce serverUrl] host]];
}

-(void)downloadContentFor:(FeedItem *)feedItem  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Note the limit 1 is needed otherwise you can hit the MALFORMED_QUERY non admin users need limit
        NSString *soql = [NSString stringWithFormat:@"select ContentData, ContentFilename from NewsFeed where id='%@' limit 1", [feedItem rowId]];
        ZKQueryResult *feed = [self.sforce query:soql];
        if ([feed size] == 0) return;   //TODO notify user ?
        ZKSObject *row = [[feed records] firstObject];
        NSString *data = [row fieldValue:@"ContentData"];
        NSString *filename = [row fieldValue:@"ContentFileName"];
        NSData *contentData = [data decodeBase64WithNewlines:NO];
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
        NSString *chatterDownload = [[dirs firstObject] stringByAppendingPathComponent:@"Chatter"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:chatterDownload])
            [[NSFileManager defaultManager] createDirectoryAtPath:chatterDownload withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *fullPath = [chatterDownload stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", [feedItem rowId], filename]];
        [contentData writeToFile:fullPath atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSWorkspace sharedWorkspace] openFile:fullPath];
        });
    });
}

-(void)dealloc {
    [feedPages release];
    [feedItems release];
    [filteredFeedItems release];
    [junkFeedItems release];
    [sforce release];
    [super dealloc];
}

@end
