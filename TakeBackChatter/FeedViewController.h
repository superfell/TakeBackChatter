//
//  FeedViewController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/23/11.
//

#import <Foundation/Foundation.h>
#import "CollectionViews.h"

@class FeedDataSource;
@class Categorizer;
@class PeopleViewController;

@interface FeedViewController : NSObject {
    CollectionViewFeed *feedCollectionView;
    FeedDataSource     *feedDataSource;

    NSSegmentedControl *feedSelectionControl;
    NSArray            *feedViewItems;
    NSArray            *feedItems;
    NSObject           *loadNewer, *loadOlder;
    
    NSWindow           *window;
    
    PeopleViewController *peopleViewController;
}

-(id)initWithDataSource:(FeedDataSource *)src;

@property (nonatomic, retain) IBOutlet PeopleViewController *peopleViewController;

@property (nonatomic, retain) IBOutlet NSWindow           *window;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *feedSelectionControl;
@property (nonatomic, retain) IBOutlet CollectionViewFeed *feedCollectionView;
@property (readonly)                       FeedDataSource *feedDataSource;
@property (nonatomic, retain)                     NSArray *feedItems;

@property (readonly) Categorizer *categorizer; // this is exposed to help with KVO / key dependency stuff.
@property (readonly) NSString    *junkSummary; // summary text, like Junk :5, or Training: 9 to go

-(IBAction)markSelectedPostsAsJunk:(id)sender;
-(IBAction)markSelectedPostsAsNotJunk:(id)sender;
-(IBAction)createPost:(id)sender;

-(IBAction)loadOlderRows:(id)sender;
-(IBAction)loadNewerRows:(id)sender;

-(IBAction)setFeedListTypeFromSender:(id)sender;

@end

@interface LoadNewer : NSObject<CollectionViewItemType> {
    FeedViewController *controller; // weak ref
}
-(id)initWithController:(FeedViewController *)c;
-(FeedViewController *)controller;
@end

@interface LoadOlder : LoadNewer {
}
@end