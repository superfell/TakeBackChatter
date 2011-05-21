//
//  FeedController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedController.h"
#import "zkSforce.h"
#import "FeedItem.h"
#import "NSDate_iso8601.h"
#import "CollectionViewFeed.h"

static int FEED_PAGE_SIZE = 25;

@implementation FeedController

@synthesize feedItems=_feedItems, sforce=_sforce, hasMore=_hasMore;
@synthesize collectionView=_collectionView;

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

-(void)startQuery {
    [self startQuery:nil];
}

-(IBAction)loadNextPage:(id)sender {
    FeedItem *last = [self.feedItems lastObject];
    [self startQuery:[last createdDate]];
}

-(void)setFeedItems:(NSArray *)items {
    [_feedItems autorelease];
    _feedItems = [items retain];
    self.hasMore = ((_feedItems.count % FEED_PAGE_SIZE) == 0) && (_feedItems.count > 0);

	[self.collectionView setAllowsMultipleSelection:YES];
	[self.collectionView setRowHeight:105];
	[self.collectionView setDrawsBackground:YES];
    [self.collectionView setContent:_feedItems];
}

-(void)setSforce:(ZKSforceClient *)c {
    [_sforce autorelease];
    _sforce = [c retain];
    if (_sforce != nil)
        [self startQuery];
    else
        self.feedItems = [NSArray array];
}

-(void)dealloc {
    [_feedItems release];
    [_sforce release];
    [_collectionView release];
    [super dealloc];
}

@end
