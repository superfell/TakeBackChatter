//
//  FeedDataSource.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSforceClient;
@class CollectionViewFeed;

@interface FeedDataSource : NSObject {
    NSArray         *feedItems, *filteredFeedItems, *junkFeedItems;
    BOOL            hasMore;
    ZKSforceClient *sforce;
}

-(id)initWithSforceClient:(ZKSforceClient *)c;

-(NSArray *)feedItems;              // all items fetched
-(NSArray *)filteredFeedItems;      // all items not considered junk
-(NSArray *)junkFeedItems;          // all junk items
-(NSUInteger)junkCount;

@property (readonly) BOOL hasMore;
@property (readonly) ZKSforceClient *sforce;

-(void)filterFeed;  // recalculated the filtered feed list.

-(IBAction)loadNewerRows:(id)sender;
-(IBAction)loadOlderRows:(id)sender;

-(void)updateStatus:(NSString *)newStatus;

@end
