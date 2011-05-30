//
//  FeedDataSource.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedDataSource.h"
#import "zkSforce.h"
#import "FeedItem.h"
#import "NSDate_iso8601.h"
#import "NSArray_extras.h"
#import "NSData-Base64Extensions.h"
#import "TakeBackChatterAppDelegate.h"
#import "UrlConnectionDelegate.h"
#import <BayesianKit/BayesianKit.h>

static int FEED_PAGE_SIZE = 25;

@interface FeedDataSource ()

@property (assign) BOOL hasMore;
@property (nonatomic,retain) NSArray *feedItems;
@property (nonatomic,retain) NSArray *filteredFeedItems;
@property (nonatomic,retain) NSArray *junkFeedItems;
-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore;

@end

@interface CachingUrlConnectionDelegate : UrlConnectionDelegateWithBlock {
}
@end

@implementation CachingUrlConnectionDelegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cr {
    // indicate that this response can be cached on disk.
    return [[[NSCachedURLResponse alloc] initWithResponse:[cr response] 
                                                     data:[cr data] 
                                                 userInfo:[cr userInfo] 
                                            storagePolicy:NSURLCacheStorageAllowed] autorelease];
}

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
    return self;
}

-(void)startActorFetch:(NSArray *)items {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableSet *actors = [NSMutableSet set];
        for (FeedItem *i in items)
            [actors addObject:[i actorId]];
        
        NSMutableString *soql = [NSMutableString stringWithCapacity:100];
        [soql appendString:@"select id, SmallPhotoUrl from User where id in ("];
        for (NSString *actor in actors)
            [soql appendFormat:@"'%@',", actor];
        [soql deleteCharactersInRange:NSMakeRange([soql length]-1,1)];
        [soql appendString:@")"];
        
        ZKQueryResult *qr = [self.sforce query:soql];
        NSString *sid = [self.sforce.sessionId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        // Note that we run this entire block on the main thread because the NSURLConnections need to be started from the main thread
        // (because they need a runloop)
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            for (ZKSObject *r in [qr records]) {
                NSLog(@"fetching image for %@", [r fieldValue:@"SmallPhotoUrl"]);
                NSURL *imgUrl = [NSURL URLWithString:[r fieldValue:@"SmallPhotoUrl"]];
                NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:imgUrl cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
                [req setValue:[NSString stringWithFormat:@"OAuth %@", sid] forHTTPHeaderField:@"Authorization"];

                CachingUrlConnectionDelegate *delegate = [CachingUrlConnectionDelegate 
                    urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *data, NSError *err) {
                    
                    NSImage *img = [[[NSImage alloc] initWithData:data] autorelease];
                    NSString *userId = [r id];
                    for (FeedItem *i in items) {
                        if ([userId isEqualToString:[i actorId]])
                            i.actorPhoto = img;
                    }
                } runOnMainThread:YES];
                [[[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES] autorelease];
            }
        });
    });
}

-(NSString *)buildQueryWithDate:(NSDate *)date newer:(BOOL)newer {
    NSMutableString *soql = [NSMutableString stringWithString:@"SELECT Id, Type, CreatedDate, CreatedById, CreatedBy.Name, " \
        "ParentId, Parent.Name, FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.LinkUrl, " \
            "(SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges), " \
            "(SELECT Id, CreatedDate, CreatedById, CreatedBy.Name, CommentBody FROM FeedComments ORDER BY CreatedDate DESC) " \
        "FROM NewsFeed "];
    if (date != nil)
        [soql appendFormat:@" where CreatedDate %@ %@ ", newer ? @">" : @"<",  [date iso8601formatted]];
    
    [soql appendFormat:@"ORDER BY CreatedDate DESC, Id DESC LIMIT %d", FEED_PAGE_SIZE];
    return soql;
}

-(void)startQueryWithDate:(NSDate *)date newer:(BOOL)newer {
    NSString *soql = [self buildQueryWithDate:date newer:newer];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ZKQueryResult *qr = [self.sforce query:soql];
        if ([qr size] == 0) return;
        NSMutableArray *res = [NSMutableArray arrayWithCapacity:[[qr records] count]];
        for (ZKSObject *r in [qr records])
            [res addObject:[FeedItem feedItemFrom:r]];
        
        [self startActorFetch:res];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSArray *newFeed = res;
            if (date != nil) {
                if (newer) 
                    newFeed = [res arrayByAddingObjectsFromArray:self.feedItems];
                else
                    newFeed = [self.feedItems arrayByAddingObjectsFromArray:res];
            }
            [self setFeedItems:newFeed updateHasMore:((date == nil) || (!newer))];
            self.feedItems = newFeed;
        });
    });
}

-(IBAction)loadNewerRows:(id)sender {
    FeedItem *first = [self.feedItems firstObject];
    [self startQueryWithDate:[first createdDate] newer:YES];
}

-(IBAction)loadOlderRows:(id)sender {
    FeedItem *last = [self.feedItems lastObject];
    [self startQueryWithDate:[last createdDate] newer:NO];
}

-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore {
    if (updateMore)
        self.hasMore = ((items.count % FEED_PAGE_SIZE) == 0) && (items.count > 0);
    self.feedItems = items;
    [self filterFeed];
}

-(void)filterFeed {
    NSPredicate *junkp = [NSPredicate predicateWithFormat:@"chanceIsJunk > 90"];
    NSArray *junk = [feedItems filteredArrayUsingPredicate:junkp];
    NSPredicate *goodp = [NSPredicate predicateWithFormat:@"chanceIsJunk <= 90"];
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

-(void)createContentPost:(NSString *)postText withFile:(NSString *)filename {
    ZKSObject *post = [ZKSObject withType:@"FeedPost"];
    [post setFieldValue:[[self.sforce currentUserInfo] userId] field:@"ParentId"];
    [post setFieldValue:[filename lastPathComponent] field:@"ContentFileName"];
    [post setFieldValue:[[NSData dataWithContentsOfFile:filename] encodeBase64] field:@"ContentData"];
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

-(void)dealloc {
    [feedItems release];
    [filteredFeedItems release];
    [junkFeedItems release];
    [sforce release];
    [super dealloc];
}

@end
