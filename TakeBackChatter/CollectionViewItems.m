//
//  CollectionViewFeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import "CollectionViewItems.h"
#import "FeedItem.h"
#import "FeedDataSource.h"
#import "LoadMarkers.h"

@implementation CollectionViewFeedItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    NSString *nibName = [theObject feedItemType] == FeedTypeContentPost ? @"ContentFeedItem" : @"FeedItem";
    [NSBundle loadNibNamed:nibName owner:self];
    
    actorPhoto.layer.borderWidth = 1.0;
    CGColorRef gray = CGColorCreateGenericGray(0.7,0.7);
    actorPhoto.layer.borderColor = gray;
    CGColorRelease(gray);
    actorPhoto.layer.cornerRadius = 10.0;
    actorPhoto.layer.masksToBounds = YES;
    
    NSSize frameSize = [view frame].size;
    NSSize textSize = [bodyTextField frame].size;
    heightExtra = frameSize.height - textSize.height;
    
    [bodyTextField setAllowsEditingTextAttributes:YES];
    [bodyTextField setSelectable:YES];
	return self;
}

-(void)showContent:(id)sender {
    [[[self representedObject] feedDataSource] downloadContentFor:[self representedObject]];
}

- (NSSize)sizeForViewWithProposedSize:(NSSize)newSize {
    static const float min_height = 100.0f;
    
    NSSize frameSize = view.frame.size;
    NSSize bodySize = bodyTextField.frame.size;

    float propBodyWidth = bodySize.width + (newSize.width - frameSize.width);
    
    float bodyHeight = [[bodyTextField cell] cellSizeForBounds:NSMakeRect(0, 0, propBodyWidth, 100000)].height;
    return NSMakeSize(newSize.width, fmaxf(min_height, bodyHeight + heightExtra));
}

@end

@implementation CollectionViewLoadNewerItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"MoreNewer" owner:self];
	return self;
}

-(IBAction)loadNewer:(id)sender {
    [(NSObject<LoadNewerDelegate> *)[representedObject controller] loadNewerRows:sender];
}

@end

@implementation CollectionViewLoadOlderItem

- (id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
	self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"MoreOlder" owner:self];
	return self;
}

-(IBAction)loadOlder:(id)sender {
    [(NSObject<LoadOlderDelegate> *)[representedObject controller] loadOlderRows:sender];
}

@end

@implementation CollectionViewPersonItem

-(id)initWithCollectionView:(AMCollectionView *)theCollectionView representedObject:(id)theObject {
    self = [super initWithCollectionView:theCollectionView representedObject:theObject];
    [NSBundle loadNibNamed:@"Person" owner:self];
    return self;
}

@end

