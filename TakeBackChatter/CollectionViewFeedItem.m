//
//  CollectionViewFeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import "CollectionViewFeedItem.h"


@implementation CollectionViewFeedItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"FeedItem" owner:self];
	return self;
}

@end
