//
//  PeopleViewController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 3/27/12.
//

#import <Foundation/Foundation.h>

@class Person;
@class PersonList;
@class FeedDataSource;
@class CollectionViewPeople;

@interface PeopleViewController : NSObject {
    FeedDataSource          *dataSource;
    CollectionViewPeople    *followingCV, *followersCV, *allCV;
    PersonList              *following;
    PersonList              *followers;
    PersonList              *all;
}

@property (nonatomic, retain) IBOutlet CollectionViewPeople *followingCV;
@property (nonatomic, retain) IBOutlet CollectionViewPeople *followersCV;
@property (nonatomic, retain) IBOutlet CollectionViewPeople *allCV;

@property (nonatomic, retain) FeedDataSource       *dataSource;

-(IBAction)searchPeople:(id)sender;

@end

// PersonFactory impls should map data into the results array, and return the nextPageUrl (if any) as the return value.
typedef NSString * (^PersonFactory)(NSUInteger httpStatusCode, NSObject *jsonValue, NSMutableArray *results);

@interface PersonList : NSObject {
    PersonFactory           personFactoryBlock;
    FeedDataSource          *dataSource;
    CollectionViewPeople    *collectionView;
    NSArray                 *items;
    NSString                *basePath;
    NSString                *nextPageUrl;
}

-(id)initWithCollectionView:(CollectionViewPeople *)cv basePath:(NSString *)basePath source:(FeedDataSource *)dataSource factory:(PersonFactory)f;
-(void)performFetch:(NSString *)searchTerm;
-(void)fetchNextPage;

@property (nonatomic, readonly) BOOL hasNextPage;
@property (nonatomic, retain, readonly) NSArray *items;

@end

@interface Person : NSObject {
    NSDictionary    *props;
    NSImage         *actorPhoto;
}

-(id)initWithProperties:(NSDictionary *)p source:(FeedDataSource *)src;

@property (nonatomic, retain) NSImage   *actorPhoto;

@end
