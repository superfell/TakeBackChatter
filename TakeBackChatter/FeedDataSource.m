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
#import "TakeBackChatterAppDelegate.h"
#import <BayesianKit/BayesianKit.h>

static int FEED_PAGE_SIZE = 25;

@interface FeedDataSource ()
@property (assign) BOOL hasMore;
@property (nonatomic,retain) NSArray *feedItems;
@property (nonatomic,retain) NSArray *filteredFeedItems;
@property (nonatomic,retain) NSArray *junkFeedItems;
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
        for (ZKSObject *r in [qr records]) {
            NSURL *imgUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@", [r fieldValue:@"SmallPhotoUrl"], sid]];
            NSImage *img = [[[NSImage alloc] initWithContentsOfURL:imgUrl] autorelease];
            NSString *userId = [r id];
            for (FeedItem *i in items) {
                if ([userId isEqualToString:[i actorId]])
                    i.actorPhoto = img;
            }
        }
    });
}

-(NSString *)buildFeedQuery:(NSDate *)before {
    NSMutableString *soql = [NSMutableString stringWithString:@"SELECT Id, Type, CreatedDate, CreatedById, CreatedBy.Name, " \
        "ParentId, Parent.Name, FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.LinkUrl, " \
            "(SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges), " \
            "(SELECT Id, CreatedDate, CreatedById, CreatedBy.Name, CommentBody FROM FeedComments ORDER BY CreatedDate DESC) " \
        "FROM NewsFeed "];
    if (before != nil)
        [soql appendFormat:@" where CreatedDate < %@ ", [before iso8601formatted]];
    [soql appendFormat:@"ORDER BY CreatedDate DESC, Id DESC LIMIT %d", FEED_PAGE_SIZE];
    return soql;
}

-(void)startQuery:(NSDate *)before {
    NSString *soql = [self buildFeedQuery:before];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ZKQueryResult *qr = [self.sforce query:soql];
        NSMutableArray *res = [NSMutableArray arrayWithCapacity:[[qr records] count]];
        for (ZKSObject *r in [qr records])
            [res addObject:[FeedItem feedItemFrom:r]];
        
        [self startActorFetch:res];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSArray *feed = before == nil ? res : [self.feedItems arrayByAddingObjectsFromArray:res];
            self.feedItems = feed;
        });
    });
}

-(IBAction)loadNewerRows:(id)sender {
    // TODO
    [self startQuery:nil];
}

-(IBAction)loadOlderRows:(id)sender {
    FeedItem *last = [self.feedItems lastObject];
    [self startQuery:[last createdDate]];
}

-(void)setFeedItems:(NSArray *)items {
    [feedItems autorelease];
    feedItems = [items retain];
    self.hasMore = ((feedItems.count % FEED_PAGE_SIZE) == 0) && (feedItems.count > 0);
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

-(void)dealloc {
    [feedItems release];
    [filteredFeedItems release];
    [junkFeedItems release];
    [sforce release];
    [super dealloc];
}

@end
