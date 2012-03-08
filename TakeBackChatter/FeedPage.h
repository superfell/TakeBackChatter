//
//  FeedPage.h
//  TakeBackChatter
//
//  Created by Simon Fell on 3/7/12.
//

#import <Foundation/Foundation.h>

// FeedPage represents a page worth of results from the chatter API.
// it contains a set of feed items along with Url to the previous & next pages.

@class FeedDataSource;
@class FeedItem;

@interface FeedPage : NSObject {
    NSDictionary    *data;
    NSArray         *items;
    FeedDataSource  *source;
}

+(id)connectFeedPage:(NSDictionary *)feed dataSource:(FeedDataSource *)src;

@property (readonly) NSURL *previousUrl;
@property (readonly) NSURL *nextUrl;
@property (readonly) NSURL *currentUrl;

@property (readonly) NSArray *feedItems;    // of FeedItem's

@property (readonly) FeedDataSource *dataSource;

@end
