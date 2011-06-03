//
//  FeedViewController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/23/11.
//

#import "FeedViewController.h"
#import "FeedItem.h"
#import "TakeBackChatterAppDelegate.h"
#import "FeedDataSource.h"
#import "zkSforce.h"
#import "CollectionViewFeedItem.h"
#import "NewPostController.h"
#import <BayesianKit/BayesianKit.h>

@interface FeedViewController ()
@property (retain) NSArray *feedViewItems;  // this are the items that drive the list view, it includes the objects for the load more... rows
@end

@implementation FeedViewController

static NSString *POOL_NAME_GOOD = @"Good";
static NSString *POOL_NAME_JUNK = @"Junk";

@synthesize collectionView, feedDataSource, feedItems;
@synthesize feedViewItems;
@synthesize window;

+(void)initialize {
    [self exposeBinding:@"feedItems"];
}

-(id)initWithDataSource:(FeedDataSource *)src {
    self = [super init];
    loadNewer = [[LoadNewer alloc] initWithController:self];
    loadOlder = [[LoadOlder alloc] initWithController:self];
    
    feedDataSource = [src retain];
    [self bind:@"feedItems" toObject:src withKeyPath:@"filteredFeedItems" options:nil];
    
    [NSBundle loadNibNamed:@"FeedList" owner:self];
    [window setTitle:feedDataSource.defaultWindowTitle];
    [window setFrameAutosaveName:[NSString stringWithFormat:@"%@ / %@", feedDataSource.defaultWindowAutosaveName, @"FeedViewController"]];
    
    [self.collectionView setAllowsMultipleSelection:YES];
	[self.collectionView setRowHeight:105];
	[self.collectionView setDrawsBackground:YES];
    [window makeKeyAndOrderFront:self];
    return self;
}

- (void)dealloc {
    [self unbind:@"feedItems"];
    [feedDataSource release];
    [collectionView release];
    [window release];
    [loadNewer release];
    [feedViewItems release];
    [super dealloc];
}

-(void)setFeedItems:(NSArray *)items {
    [feedItems autorelease];
    feedItems = [items retain];
    
    NSMutableArray *fv = [NSMutableArray arrayWithCapacity:[feedItems count] + 2];
    [fv addObject:loadNewer];
    [fv addObjectsFromArray:feedItems];
    if ([feedDataSource hasMore])
        [fv addObject:loadOlder];
    
    self.feedViewItems = fv;
    [self.collectionView setContent:fv];
}

-(void)catorgorizeSelectedPostsAs:(NSString *)poolName {
    NSArray *selection = [self.collectionView selectedObjects];
    NSMutableString *text = [NSMutableString string];
    for (FeedItem *item in selection)
        [text appendString:[item classificationText]];
    
    BKClassifier *classifier = [[NSApp delegate] classifier];
    [classifier trainWithString:text forPoolNamed:poolName];
    [feedDataSource filterFeed];
}

-(IBAction)markSelectedPostsAsJunk:(id)sender {
    [self catorgorizeSelectedPostsAs:POOL_NAME_JUNK];
}

-(IBAction)markSelectedPostsAsNotJunk:(id)sender {
    [self catorgorizeSelectedPostsAs:POOL_NAME_GOOD];
}

-(IBAction)loadOlderRows:(id)sender {
    [feedDataSource loadOlderRows:sender];
}

-(IBAction)loadNewerRows:(id)sender {
    [feedDataSource loadNewerRows:sender];
}

-(IBAction)createPost:(id)sender {
    [[NewPostController postControllerFor:feedDataSource] retain];
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
    if (srcPropName != nil)
        [self bind:@"feedItems" toObject:feedDataSource withKeyPath:srcPropName options:nil];
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