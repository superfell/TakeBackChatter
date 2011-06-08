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
}

-(void)persist;

-(int)chanceIsJunk:(FeedItem *)item;

-(void)categorizeItemsAsJunk:(NSArray *)items;
-(void)categorizeItemsAsGood:(NSArray *)items;

@end
