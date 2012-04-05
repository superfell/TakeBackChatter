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
    CollectionViewPeople    *followingCV, *followersCV;
    NSArray                 *following, *followers;
}


@property (nonatomic, retain) IBOutlet CollectionViewPeople *followingCV;
@property (nonatomic, retain) IBOutlet CollectionViewPeople *followersCV;

@property (nonatomic, retain) FeedDataSource       *dataSource;

@property (readonly) NSArray *following;
@property (readonly) NSArray *followers;

@end

@interface Person : NSObject {
    NSDictionary    *props;
    NSImage         *actorPhoto;
}

-(id)initWithProperties:(NSDictionary *)p source:(FeedDataSource *)src;

@property (nonatomic, retain) NSImage   *actorPhoto;

@end