//
//  CollectionViewFeed.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import <Foundation/Foundation.h>
#import "AMCollectionView.h"

@interface CollectionViewFeed : AMCollectionView {
}
@end

// Your representedObjects can implement this protocol, and we'll let them declare
// which ItemType class to use, the returned class should implement the standard
// collectionItem initializer
@protocol CollectionViewItemType <NSObject>
-(Class)classOfItemForCollectionView:(CollectionViewFeed *)cv;
@end

