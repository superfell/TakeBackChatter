//
//  FeedDataSource.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSforceClient;
@class CollectionViewFeed;
@class FeedItem;

@interface FeedDataSource : NSObject {
    NSArray         *feedItems, *filteredFeedItems, *junkFeedItems;
    NSMutableArray  *feedPages;
    BOOL            hasMore;
    ZKSforceClient *sforce;
}

-(id)initWithSforceClient:(ZKSforceClient *)c;

-(NSArray *)feedItems;              // all items fetched
-(NSArray *)filteredFeedItems;      // all items not considered junk
-(NSArray *)junkFeedItems;          // all junk items
-(NSArray *)feedPages;              // all pages fetched
-(NSUInteger)junkCount;

@property (readonly) BOOL hasMore;
@property (readonly) ZKSforceClient *sforce;
@property (readonly) NSURL *serverUrl;
@property (readonly) NSString *sessionId;

-(void)filterFeed;  // recalculated the filtered feed list.

-(IBAction)loadNewerRows:(id)sender;
-(IBAction)loadOlderRows:(id)sender;

-(void)updateStatus:(NSString *)newStatus;
-(void)createContentPost:(NSString *)postText content:(NSData *)content contentName:(NSString *)name;
-(void)downloadContentFor:(FeedItem *)feedItem;

@property (readonly) NSString *defaultWindowTitle;
@property (readonly) NSString *defaultWindowAutosaveName;


@end
