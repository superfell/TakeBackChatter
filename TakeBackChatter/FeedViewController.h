//
//  FeedViewController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/23/11.
//

#import <Foundation/Foundation.h>

@class CollectionViewFeed;
@class FeedDataSource;

@interface FeedViewController : NSObject {
    CollectionViewFeed *_collectionView;
    FeedDataSource     *_dataSource;
    NSArray            *_feedItems;
}

-(id)initWithDataSource:(FeedDataSource *)src;

@property (nonatomic, retain)  IBOutlet CollectionViewFeed *collectionView;
@property (readonly)                        FeedDataSource *feedDataSource;
@property (nonatomic, retain)                      NSArray *feedItems;

-(IBAction)markSelectedPostsAsJunk:(id)sender;
-(IBAction)markSelectedPostsAsNotJunk:(id)sender;

@end
