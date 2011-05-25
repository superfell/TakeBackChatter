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

@synthesize collectionView, feedDataSource, feedItems;
@synthesize window;

+(void)initialize {
    [self exposeBinding:@"feedItems"];
}

-(id)initWithDataSource:(FeedDataSource *)src {
    self = [super init];
    feedDataSource = [src retain];
    [self bind:@"feedItems" toObject:src withKeyPath:@"feedItems" options:nil];
    
    ZKSforceClient *c = feedDataSource.sforce;
    [NSBundle loadNibNamed:@"FeedList" owner:self];
    [window setTitle:[NSString stringWithFormat:@"%@ / %@", [[c currentUserInfo] userName], [[c serverUrl] host]]];
    [window setFrameAutosaveName:[NSString stringWithFormat:@"%@ / %@", [[c currentUserInfo] userId], [[c serverUrl] host]]];
    
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
    [super dealloc];
}

-(void)setFeedItems:(NSArray *)items {
    [feedItems autorelease];
    feedItems = [items retain];
    [self.collectionView setContent:feedItems];
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
    [feedDataSource loadOlderRows:sender];
}

-(IBAction)loadNewerRows:(id)sender {
    [feedDataSource loadNewerRows:sender];
}
@end
