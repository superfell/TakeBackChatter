//
//  Categorizer.h
//  TakeBackChatter
//
//  Created by Simon Fell on 6/7/11.
//

#import <Foundation/Foundation.h>

@class BKClassifier;
@class FeedItem;

@interface Categorizer : NSObject {
    BKClassifier      *classifier;
    NSMutableSet      *goodIds, *junkIds;
}

-(void)persist;

// if the item has been explicitly categorized, then we'll return that, regardless of what the stats say.
-(int)chanceIsJunk:(FeedItem *)item;

-(void)categorizeItemsAsJunk:(NSArray *)items;
-(void)categorizeItemsAsGood:(NSArray *)items;

@end
