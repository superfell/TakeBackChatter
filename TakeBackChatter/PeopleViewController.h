//
//  PeopleViewController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 3/27/12.
//

#import <Foundation/Foundation.h>

@class FeedDataSource;
@class CollectionViewPeople;

@interface PeopleViewController : NSObject {
    FeedDataSource          *dataSource;
    CollectionViewPeople    *collectionView;
    
    NSArray                 *following;
}


@property (nonatomic, retain) IBOutlet CollectionViewPeople *collectionView;

@property (nonatomic, retain) FeedDataSource       *dataSource;

@property (readonly) NSArray *following;

@end