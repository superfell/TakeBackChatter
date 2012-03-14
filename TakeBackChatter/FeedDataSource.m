//
//  FeedDataSource.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedDataSource.h"
#import "zkSforce.h"
#import "Feed.h"
#import "FeedItem.h"
#import "FeedPage.h"
#import "NSDate_iso8601.h"
#import "NSArray_extras.h"
#import "NSData-Base64Extensions.h"
#import "TakeBackChatterAppDelegate.h"
#import "prefs.h"
#import "NSString-Base64Extensions.h"

@interface FeedDataSource ()

@property (retain) NSArray *feeds;

-(void)fetchFeeds;

@end

@implementation FeedDataSource

@synthesize feeds, feed;

-(id)initWithSforceClient:(ZKSforceClient *)c {
    self = [super init];
    sforce = [c retain];
    [self fetchFeeds];
    return self;
}
        
-(NSURL *)serverUrl {
    return sforce.serverUrl;
}

-(NSString *)sessionId {
    return sforce.sessionId;
}

-(NSString *)userName {
    return [[sforce currentUserInfo] userName];
}

-(NSString *)userId {
    return [[sforce currentUserInfo] userId];
}

-(void)fetchJsonUrl:(NSURL *)url done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:[NSString stringWithFormat:@"OAuth %@", self.sessionId] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"false" forHTTPHeaderField:@"X-Chatter-Entity-Encoding"];
    JsonUrlConnectionDelegateWithBlock *delegate = [JsonUrlConnectionDelegateWithBlock
                                                    urlDelegateWithBlock:doneBlock runOnMainThread:runOnMain];

    NSLog(@"starting request for %@ %@", [req HTTPMethod], [req URL]);
    [[[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES] autorelease];
}

-(void)fetchJsonPath:(NSString *)path done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain {
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.serverUrl];
    [self fetchJsonUrl:url done:doneBlock runOnMainThread:runOnMain];
}

-(void)fetchFeeds {
    [self fetchJsonPath:@"/services/data/v24.0/chatter/feeds" done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        NSMutableArray *results = [NSMutableArray array];
        NSArray *jsonFeeds = [(NSDictionary *)jsonValue objectForKey:@"feeds"];
        Feed *myChatter = nil;
        for (NSDictionary *f in jsonFeeds) {
            Feed *newFeed = [Feed connectFeed:[f objectForKey:@"feedItemsUrl"] label:[f objectForKey:@"label"] source:self];
            [results addObject:newFeed];
            if ([newFeed isMyChatter])
                myChatter = [[newFeed retain] autorelease];
        }
        self.feeds = [NSArray arrayWithArray:results];
        self.feed = myChatter;
        
    } runOnMainThread:YES];
}

-(void)checkSaveResult:(ZKSaveResult *)sr {
    if ([sr success]) {
        [feed loadNewerRows:self];
    } else {
        NSLog(@"%@ %@", [sr statusCode], [sr message]);
    }
}

-(void)updateStatus:(NSString *)newStatus {
    ZKSObject *user = [ZKSObject withTypeAndId:@"User" sfId:[[sforce currentUserInfo] userId]];
    [user setFieldValue:newStatus field:@"CurrentStatus"];
    ZKSaveResult *sr = [[sforce update:[NSArray arrayWithObject:user]] firstObject];
    [self checkSaveResult:sr];
}

-(void)createContentPost:(NSString *)postText content:(NSData *)content contentName:(NSString *)name {
    ZKSObject *post = [ZKSObject withType:@"FeedPost"];
    [post setFieldValue:name field:@"ContentFileName"];
    [post setFieldValue:[content encodeBase64] field:@"ContentData"];
    [post setFieldValue:[[sforce currentUserInfo] userId] field:@"ParentId"];
    [post setFieldValue:postText field:@"Body"];
    ZKSaveResult *sr = [[sforce create:[NSArray arrayWithObject:post]] firstObject];
    [self checkSaveResult:sr];
}

-(void)downloadContentFor:(FeedItem *)feedItem  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Note the limit 1 is needed otherwise you can hit the MALFORMED_QUERY non admin users need limit
        NSString *soql = [NSString stringWithFormat:@"select ContentData, ContentFilename from NewsFeed where id='%@' limit 1", [feedItem rowId]];
        ZKQueryResult *newsFeed = [sforce query:soql];
        if ([newsFeed size] == 0) return;   //TODO notify user ?
        ZKSObject *row = [[newsFeed records] firstObject];
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

-(NSString *)defaultWindowTitle {
    return [NSString stringWithFormat:@"%@ / %@", [self userName], [[self serverUrl] host]];
}

-(NSString *)defaultWindowAutosaveName {
    return [NSString stringWithFormat:@"%@ / %@", [self userId], [[self serverUrl] host]];
}

-(void)dealloc {
    [sforce release];
    [feed release];
    [feeds release];
    [super dealloc];
}

@end
