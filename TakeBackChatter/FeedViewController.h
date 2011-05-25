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
    CollectionViewFeed *collectionView;
    FeedDataSource     *feedDataSource;
    NSArray            *feedItems;
    NSWindow           *window;
}

-(id)initWithDataSource:(FeedDataSource *)src;

@property (nonatomic, retain) IBOutlet NSWindow           *window;
@property (nonatomic, retain) IBOutlet CollectionViewFeed *collectionView;
@property (readonly)                       FeedDataSource *feedDataSource;
@property (nonatomic, retain)                     NSArray *feedItems;


-(IBAction)markSelectedPostsAsJunk:(id)sender;
-(IBAction)markSelectedPostsAsNotJunk:(id)sender;

-(IBAction)loadOlderRows:(id)sender;
-(IBAction)loadNewerRows:(id)sender;

@end
