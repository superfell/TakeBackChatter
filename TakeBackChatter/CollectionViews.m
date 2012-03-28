//
//  CollectionViewFeed.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import "CollectionViews.h"
#import "CollectionViewItems.h"

@implementation CollectionViewFeed

- (CollectionViewFeedItem *)newItemForRepresentedObject:(id)object {
    if ([object conformsToProtocol:@protocol(CollectionViewItemType)]) {
        Class ic = [object classOfItemForCollectionView:self];
        return [[ic alloc] initWithCollectionView:self representedObject:object];
    }
	return [[CollectionViewFeedItem alloc] initWithCollectionView:self representedObject:object];
}

-(void)setDefaultProperties {
    [self setAllowsMultipleSelection:YES];
	[self setRowHeight:105];
	[self setDrawsBackground:YES];
    [self setBackgroundColors:[NSArray arrayWithObjects:[NSColor whiteColor], 
                                                        [NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0],
                                                        nil]];
}

@end

@implementation CollectionViewPeople 

-(CollectionViewPersonItem *)newItemForRepresentedObject:(id)object {
    return [[CollectionViewPersonItem alloc] initWithCollectionView:self representedObject:object];
}

-(void)setDefaultProperties {
    [self setAllowsMultipleSelection:NO];
	[self setRowHeight:105];
	[self setDrawsBackground:YES];
    [self setBackgroundColors:[NSArray arrayWithObjects:[NSColor whiteColor], 
                               [NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0],
                               nil]];
}

@end