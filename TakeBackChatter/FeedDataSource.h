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

-(NSArray *)feedItems;
-(NSArray *)filteredFeedItems;
-(NSArray *)junkFeedItems;

@property (readonly) BOOL hasMore;
@property (readonly) ZKSforceClient *sforce;

-(IBAction)loadNewerRows:(id)sender;
-(IBAction)loadOlderRows:(id)sender;

@end
