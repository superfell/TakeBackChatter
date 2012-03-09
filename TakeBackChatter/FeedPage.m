//
//  FeedPage.m
//  TakeBackChatter
//
//  Created by Simon Fell on 3/7/12.
//

#import "FeedPage.h"
#import "FeedItem.h"
#import "FeedDataSource.h"

@implementation FeedPage

@synthesize dataSource=source;

-(id)initFeedPage:(NSDictionary *)feed dataSource:(FeedDataSource *)src {
    self = [super init];
    data = [feed retain];
    source = [src retain]; // TODO retain loop ?
    NSArray *srcItems = [data objectForKey:@"items"];
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:[srcItems count]];
    for (NSDictionary *i in srcItems)
        [res addObject:[FeedItem connectFeedItem:i dataSource:src]];
    items = [[NSArray arrayWithArray:res] retain];
    return self;
}

-(void)dealloc {
    [data release];
    [source release];
    [items release];
    [super dealloc];
}

+(id)connectFeedPage:(NSDictionary *)feed dataSource:(FeedDataSource *)src {
    return [[[FeedPage alloc] initFeedPage:feed dataSource:src] autorelease];
}

-(NSURL *)url:(NSString *)key {
    NSObject *rel = [data objectForKey:key];
    if (rel == nil || rel == [NSNull null]) return nil;
    return [NSURL URLWithString:(NSString *)rel relativeToURL:source.serverUrl];
}

-(NSURL *)previousUrl {
    return [self url:@"previousPageUrl"];
}

-(NSURL *)nextUrl {
    return [self url:@"nextPageUrl"];
}

-(NSURL *)currentUrl {
    return [self url:@"currentPageUrl"];
}

-(NSArray *)feedItems {
    return [[items retain] autorelease];
}

@end
