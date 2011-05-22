//
//  FeedController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSforceClient;
@class CollectionViewFeed;

@interface FeedController : NSObject {
}

@property (retain) IBOutlet CollectionViewFeed *collectionView;

@property (nonatomic, retain) NSArray *feedItems;
@property (nonatomic, assign) BOOL hasMore;

@property (nonatomic, retain) ZKSforceClient *sforce;

-(IBAction)loadNextPage:(id)sender;

-(IBAction)markSelectedPostsAsJunk:(id)sender;
-(IBAction)markSelectedPostsAsNotJunk:(id)sender;

@end
