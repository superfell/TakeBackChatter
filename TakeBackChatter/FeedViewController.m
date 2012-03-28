//
//  FeedViewController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/23/11.
//

#import "FeedViewController.h"
#import "Feed.h"
#import "FeedItem.h"
#import "TakeBackChatterAppDelegate.h"
#import "FeedDataSource.h"
#import "zkSforce.h"
#import "CollectionViewItems.h"
#import "NewPostController.h"
#import "Categorizer.h"

@interface FeedViewController ()
@property (retain) NSArray *feedViewItems;  // this are the items that drive the list view, it includes the objects for the load more... rows
-(void)showTrainingHelpWindow;
@end

@implementation FeedViewController

@synthesize feedCollectionView, feedDataSource, feedItems;
@synthesize feedViewItems;
@synthesize window, feedSelectionControl;

+(void)initialize {
    [self exposeBinding:@"feedItems"];
}

+(NSSet *)keyPathsForValuesAffectingJunkSummary {
    return [NSSet setWithObjects:@"feedDataSource.junkCount", @"categorizer.trainingLeft", @"categorizer.isTraining", nil];
}

-(id)initWithDataSource:(FeedDataSource *)src {
    self = [super init];
    loadNewer = [[LoadNewer alloc] initWithController:self];
    loadOlder = [[LoadOlder alloc] initWithController:self];
    
    feedDataSource = [src retain];
    
    [NSBundle loadNibNamed:@"FeedList" owner:self];
    [window setTitle:feedDataSource.defaultWindowTitle];
    [window setFrameAutosaveName:[NSString stringWithFormat:@"%@ / %@", feedDataSource.defaultWindowAutosaveName, @"FeedViewController"]];
    
    [self.feedCollectionView setDefaultProperties];
    
    [self.feedSelectionControl setSelectedSegment:[self.categorizer isTraining] ? 0 : 1];
    [window makeKeyAndOrderFront:self];
    [feedDataSource addObserver:self forKeyPath:@"feed" options:0 context:nil];
    
    if ([self.categorizer categorizedCount] == 0)
        [self showTrainingHelpWindow];
    
    return self;
}

- (void)dealloc {
    [self unbind:@"feedItems"];
    [feedDataSource removeObserver:self forKeyPath:@"feed"];
    [feedDataSource release];
    [feedCollectionView release];
    [window release];
    [loadNewer release];
    [feedViewItems release];
    [super dealloc];
}

-(void)showTrainingHelpWindow {
    [NSBundle loadNibNamed:@"TrainingHelp" owner:self];
}

-(void)setFeedItems:(NSArray *)items {
    [feedItems autorelease];
    feedItems = [items retain];
    
    NSMutableArray *fv = [NSMutableArray arrayWithCapacity:[feedItems count] + 2];
    [fv addObject:loadNewer];
    [fv addObjectsFromArray:feedItems];
    if ([[feedDataSource feed] hasMore])
        [fv addObject:loadOlder];
    
    self.feedViewItems = fv;
    [self.feedCollectionView setContent:fv];
}

-(IBAction)markSelectedPostsAsJunk:(id)sender {
    [[[NSApp delegate] categorizer] categorizeItemsAsJunk:[self.feedCollectionView selectedObjects]];
    [[feedDataSource feed] filterFeed];
}

-(IBAction)markSelectedPostsAsNotJunk:(id)sender {
    [[[NSApp delegate] categorizer] categorizeItemsAsGood:[self.feedCollectionView selectedObjects]];
    [[feedDataSource feed] filterFeed];
}

-(IBAction)loadOlderRows:(id)sender {
    [[feedDataSource feed] loadOlderRows:sender];
}

-(IBAction)loadNewerRows:(id)sender {
    [[feedDataSource feed] loadNewerRows:sender];
}

-(IBAction)createPost:(id)sender {
    [[NewPostController postControllerFor:feedDataSource] retain];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"feed"]) {
        // the feed property of the data source has changed to a different feed, rebind to it if needed
        [self setFeedListTypeFromSender:feedSelectionControl];
    }
}

-(IBAction)setFeedListTypeFromSender:(id)sender {
    NSSegmentedControl *s = sender;
    NSInteger t = [s selectedSegment];
    NSString *srcPropName = nil;
    switch (t) {
        case 0 : srcPropName = @"feedItems"; break;
        case 1 : srcPropName = @"filteredFeedItems"; break;
        case 2 : srcPropName = @"junkFeedItems"; break;
    }
    NSLog(@"feed = %@, propName=%@", [feedDataSource feed], srcPropName);
    if (srcPropName != nil && [feedDataSource feed] != nil) {
        [self bind:@"feedItems" toObject:[feedDataSource feed] withKeyPath:srcPropName options:nil];
        [[feedDataSource feed] loadNewerRows:self];
    }
}

-(NSString *)junkSummary {
    Categorizer *c = [self categorizer];
    return [c isTraining] ? [NSString stringWithFormat:@"Training: %lu to go", (unsigned long)[c trainingLeft]] :
                            [NSString stringWithFormat:@"Junk: %lu", (unsigned long)[[feedDataSource feed] junkCount]];
}

-(Categorizer *)categorizer {
    return [[NSApp delegate] categorizer];
}

@end

@implementation LoadNewer

-(id)initWithController:(FeedViewController *)c {
    self = [super init];
    controller = c;
    return self;
}

-(FeedViewController *)controller {
    return controller;
}

-(Class)classOfItemForCollectionView:(CollectionViewFeed *)cv {
    return [CollectionViewLoadNewerItem class];
}

@end

@implementation LoadOlder

-(Class)classOfItemForCollectionView:(CollectionViewFeed *)cv {
    return [CollectionViewLoadOlderItem class];
}

@end