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
    NSArray         *_feedItems;
    BOOL            _hasMore;
    ZKSforceClient *_sforce;
}

@property (nonatomic, retain) NSArray *feedItems;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, retain) ZKSforceClient *sforce;

-(IBAction)loadNewPage:(id)sender;
-(IBAction)loadOldPage:(id)sender;

@end
