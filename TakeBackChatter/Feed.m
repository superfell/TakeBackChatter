//
//  Feed.m
//  TakeBackChatter
//
//  Created by Simon Fell on 3/8/12.
//

#import "Feed.h"
#import "FeedDataSource.h"
#import "FeedPage.h"
#import "FeedItem.h"
#import "prefs.h"

@interface Feed ()

@property (assign) BOOL hasMore;
@property (nonatomic,retain) NSArray *feedItems;
@property (nonatomic,retain) NSArray *filteredFeedItems;
@property (nonatomic,retain) NSArray *junkFeedItems;

-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore;

@end

@implementation Feed

@synthesize hasMore, feedItems, filteredFeedItems, junkFeedItems;

// This tells KVO (and theirfore the UI binding), that the 'junkCount' property value is affected by changes to the 'junkFeedItems' property
// We only have the junkCount property because it doesn't appear possible to bind to the count property of NSArray (which seems odd)
+(NSSet *)keyPathsForValuesAffectingJunkCount {
    return [NSSet setWithObject:@"junkFeedItems"];
}

-(id)initFeed:(NSString *)basePath label:(NSString *)lbl source:(FeedDataSource *)src {
    self = [super init];
    baseUrl = [[NSURL URLWithString:basePath relativeToURL:src.serverUrl] retain];
    label = [lbl retain];
    dataSource = [src retain];
    feedPages = [[NSMutableArray alloc] init];
    return self;
}

-(void)dealloc {
    [label release];
    [dataSource release];
    [feedPages release];
    [feedItems release];
    [filteredFeedItems release];
    [junkFeedItems release];
    [super dealloc];
}

+(id)connectFeed:(NSString *)baseUrl label:(NSString *)label source:(FeedDataSource *)src {
    Feed *f = [[[Feed alloc] initFeed:baseUrl label:label source:src] autorelease];
    return f;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ (url=%@)", label, baseUrl];
}

-(NSString *)label {
    return label;
}

-(FeedDataSource *)dataSource {
    return dataSource;
}

-(NSArray *)feedPages {
    return feedPages;
}

-(BOOL)isMyChatter {
    return [[baseUrl path] rangeOfString:@"chatter/feeds/news/me/feed-items"].location != NSNotFound;
}

-(NSArray *)resolveNewFeed:(FeedPage *)newFrontPage {
    if ([feedPages count] > 0) {
        // the set of feed Item Ids in the current front page.
        NSMutableSet *fp = [[[NSMutableSet alloc] init] autorelease];
        for (FeedItem *i in [[feedPages objectAtIndex:0] feedItems]) {
            [fp addObject:[i rowId]];
        }
        NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:[[newFrontPage feedItems] count]];
        for (FeedItem *i in [newFrontPage feedItems]) {
            if ([fp containsObject:[i rowId]]) break;
            [newItems addObject:i];
        }
        // nothing new to add, just return the current feed.
        if ([newItems count] == 0)
            return self.feedItems;
        // got at least one new item, add the page, and build the new feed items list.
        [feedPages insertObject:newFrontPage atIndex:0];
        return [newItems arrayByAddingObjectsFromArray:self.feedItems];
        
    } else {
        [feedPages insertObject:newFrontPage atIndex:0];
        return [newFrontPage feedItems];
    }
}

-(void)fetchFeed:(NSURL *)feedUrl newer:(BOOL)newer {
    [dataSource fetchJsonUrl:feedUrl done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        if (httpStatusCode == 200) {
            FeedPage *page = [FeedPage connectFeedPage:(NSDictionary *)jsonValue dataSource:dataSource];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSArray *newFeed;
                if (newer) {
                    newFeed = [self resolveNewFeed:page];
                } else {
                    [feedPages addObject:page];
                    newFeed = [self.feedItems arrayByAddingObjectsFromArray:[page feedItems]];
                }
                
                [self setFeedItems:newFeed updateHasMore:YES];
                self.feedItems = newFeed;
            });
            
        } else {
            NSLog(@"Feed request returned HTTP status code %lu", httpStatusCode);
        }
    } runOnMainThread:YES];
}

-(IBAction)loadNewerRows:(id)sender {
    [self fetchFeed:baseUrl newer:YES];
}

-(IBAction)loadOlderRows:(id)sender {
    NSURL *feedUrl = [[feedPages lastObject] nextUrl];
    [self fetchFeed:feedUrl newer:NO];
}

-(void)setFeedItems:(NSArray *)items updateHasMore:(BOOL)updateMore {
    if (updateMore)
        self.hasMore = [[feedPages lastObject] nextUrl] != nil;
    self.feedItems = items;
    [self filterFeed];
}

-(void)filterFeed {
    NSNumber *junkThreshold = [NSNumber numberWithLong:[[NSUserDefaults standardUserDefaults] integerForKey:PREFS_JUNK_THRESHOLD]];
    NSPredicate *junkp = [NSPredicate predicateWithFormat:@"chanceIsJunk > %@", junkThreshold];
    NSArray *junk = [feedItems filteredArrayUsingPredicate:junkp];
    NSPredicate *goodp = [NSPredicate predicateWithFormat:@"chanceIsJunk <= %@", junkThreshold];
    NSArray *filtered = [feedItems filteredArrayUsingPredicate:goodp];
    self.junkFeedItems = junk;
    self.filteredFeedItems = filtered;
}

-(NSUInteger)junkCount {
    return self.junkFeedItems.count;
}

@end
