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
    NSString           *_windowTitle;
}

-(id)initWithDataSource:(FeedDataSource *)src;

@property (nonatomic, retain)  IBOutlet CollectionViewFeed *collectionView;
@property (readonly)                        FeedDataSource *feedDataSource;
@property (nonatomic, retain)                      NSArray *feedItems;

@property (readonly) NSString *windowTitle;

-(IBAction)markSelectedPostsAsJunk:(id)sender;
-(IBAction)markSelectedPostsAsNotJunk:(id)sender;

-(IBAction)loadOlderRows:(id)sender;
-(IBAction)loadNewerRows:(id)sender;

@end
