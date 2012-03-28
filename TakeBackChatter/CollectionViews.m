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

@end

@implementation CollectionViewPeople 

-(CollectionViewPersonItem *)newItemForRepresentedObject:(id)object {
    return [[CollectionViewPersonItem alloc] initWithCollectionView:self representedObject:object];
}

@end