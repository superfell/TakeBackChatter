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
#import <BayesianKit/BayesianKit.h>

@implementation FeedViewController

static NSString *POOL_NAME_GOOD = @"Good";
static NSString *POOL_NAME_JUNK = @"Junk";

@synthesize collectionView=_collectionView, feedDataSource=_dataSource, feedItems=_feedItems;
@synthesize windowTitle=_windowTitle;

+(void)initialize {
    [self exposeBinding:@"feedItems"];
}

-(id)initWithDataSource:(FeedDataSource *)src {
    self = [super init];
    _dataSource = [src retain];
    [self bind:@"feedItems" toObject:src withKeyPath:@"feedItems" options:nil];
    
    ZKSforceClient *c = _dataSource.sforce;
    _windowTitle = [[NSString stringWithFormat:@"%@ / %@", [[c currentUserInfo] userName], [[c serverUrl] host]] retain];
    [NSBundle loadNibNamed:@"FeedList" owner:self];

    [self.collectionView setAllowsMultipleSelection:YES];
	[self.collectionView setRowHeight:105];
	[self.collectionView setDrawsBackground:YES];
    return self;
}

- (void)dealloc {
    [self unbind:@"feedItems"];
    [_dataSource release];
    [_collectionView release];
    [_windowTitle release];
    [super dealloc];
}

-(void)setFeedItems:(NSArray *)feedItems {
    [_feedItems autorelease];
    _feedItems = [feedItems retain];
    [self.collectionView setContent:_feedItems];
}

-(void)catorgorizeSelectedPostsAs:(NSString *)poolName {
    NSArray *selection = [self.collectionView selectedObjects];
    NSMutableString *text = [NSMutableString string];
    for (FeedItem *item in selection)
        [text appendString:[item classificationText]];
    
    BKClassifier *classifier = [[NSApp delegate] classifier];
    [classifier trainWithString:text forPoolNamed:poolName];
}

-(IBAction)markSelectedPostsAsJunk:(id)sender {
    [self catorgorizeSelectedPostsAs:POOL_NAME_JUNK];
}

-(IBAction)markSelectedPostsAsNotJunk:(id)sender {
    [self catorgorizeSelectedPostsAs:POOL_NAME_GOOD];
}

-(IBAction)loadOlderRows:(id)sender {
    [_dataSource loadOlderRows:sender];
}

-(IBAction)loadNewerRows:(id)sender {
    [_dataSource loadNewerRows:sender];
}
@end
