//
//  Feed.h
//  TakeBackChatter
//
//  Created by Simon Fell on 3/8/12.
//

#import <Foundation/Foundation.h>

@class FeedDataSource;

@interface Feed : NSObject {
    NSString        *label;
    NSURL           *baseUrl;
    NSArray         *feedItems, *filteredFeedItems, *junkFeedItems;
    NSMutableArray  *feedPages;
    BOOL            hasMore;
    FeedDataSource  *dataSource;
}

+(id)connectFeed:(NSString *)baseUrl label:(NSString *)label source:(FeedDataSource *)src;

@property (readonly) NSString *label;
@property (readonly) BOOL hasMore;
@property (readonly) BOOL isMyChatter;  // is this the "My Chatter" feed ?

-(NSArray *)feedItems;              // all items fetched
-(NSArray *)filteredFeedItems;      // all items not considered junk
-(NSArray *)junkFeedItems;          // all junk items
-(NSArray *)feedPages;              // all pages fetched
-(NSUInteger)junkCount;

-(void)filterFeed;  // recalculated the filtered feed list.

-(IBAction)loadNewerRows:(id)sender;
-(IBAction)loadOlderRows:(id)sender;

@property (readonly) FeedDataSource *dataSource;

@end
