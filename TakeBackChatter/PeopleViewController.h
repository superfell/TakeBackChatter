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
    CollectionViewPeople    *followingCV, *followersCV, *allCV;
    NSArray                 *following, *followers;
}


@property (nonatomic, retain) IBOutlet CollectionViewPeople *followingCV;
@property (nonatomic, retain) IBOutlet CollectionViewPeople *followersCV;
@property (nonatomic, retain) IBOutlet CollectionViewPeople *allCV;

@property (nonatomic, retain) FeedDataSource       *dataSource;

@property (readonly) NSArray *following;
@property (readonly) NSArray *followers;
@property (readonly) NSArray *all;

-(IBAction)searchPeople:(id)sender;

@end

@interface Person : NSObject {
    NSDictionary    *props;
    NSImage         *actorPhoto;
}

-(id)initWithProperties:(NSDictionary *)p source:(FeedDataSource *)src;

@property (nonatomic, retain) NSImage   *actorPhoto;

@end