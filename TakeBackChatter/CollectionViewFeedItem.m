//
//  CollectionViewFeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import "CollectionViewFeedItem.h"
#import "FeedViewController.h"

@implementation CollectionViewFeedItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"FeedItem" owner:self];
	return self;
}

- (NSSize)sizeForViewWithProposedSize:(NSSize)newSize {
    static const float min_height = 100.0f;
    
    NSSize frameSize = view.frame.size;
    NSSize bodySize = bodyTextField.frame.size;

    float propBodyWidth = bodySize.width + (newSize.width - frameSize.width);
    
    float bodyHeight = [[bodyTextField cell] cellSizeForBounds:NSMakeRect(0, 0, propBodyWidth, 100000)].height;
    return NSMakeSize(newSize.width, fmaxf(min_height, bodyHeight + (105 - 56)));
}

@end

@implementation CollectionViewLoadNewerItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"MoreNewer" owner:self];
	return self;
}

-(IBAction)loadNewer:(id)sender {
    [[representedObject controller] loadNewerRows:sender];
}

@end

@implementation CollectionViewLoadOlderItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"MoreOlder" owner:self];
	return self;
}

-(IBAction)loadOlder:(id)sender {
    [[representedObject controller] loadOlderRows:sender];
}

@end