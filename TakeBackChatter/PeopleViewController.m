//
//  PeopleViewController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 3/27/12.
//

#import "PeopleViewController.h"
#import "FeedDataSource.h"
#import "CollectionViews.h"
#import "CollectionViewItems.h"
#import "LoadMarkers.h"

@implementation PeopleViewController

@synthesize followingCV, followersCV, allCV, dataSource;

-(void)dealloc {
    [dataSource release];
    [followersCV release];
    [followingCV release];
    [allCV release];
    [following release];
    [followers release];
    [all release];
    [super dealloc];
}

-(IBAction)searchPeople:(id)sender {
    [all performFetch:[sender stringValue]];
}

-(void)setDataSource:(FeedDataSource *)src {
    [dataSource autorelease];
    dataSource = [src retain];
    [followingCV setDefaultProperties];
    [followersCV setDefaultProperties];
    [allCV setDefaultProperties];

    all = [[PersonList alloc] initWithCollectionView:allCV basePath:@"chatter/users" source:src 
            factory:^NSString *(NSUInteger httpStatusCode, NSObject *jsonValue, NSMutableArray *results) {
                NSArray *users = [(NSDictionary *)jsonValue objectForKey:@"users"];
                for (NSDictionary *u in users) {
                    Person *person = [[[Person alloc] initWithProperties:u source:dataSource] autorelease];
                    [results addObject:person];
                }
                return [(NSDictionary *)jsonValue objectForKey:@"nextPageUrl"];
            }];
    
    followers = [[PersonList alloc] initWithCollectionView:followersCV basePath:@"chatter/users/me/followers" source:src 
           factory:^NSString *(NSUInteger httpStatusCode, NSObject *jsonValue, NSMutableArray *results) {
               NSArray *sub = [(NSDictionary *)jsonValue objectForKey:@"followers"];
               for (NSDictionary *f in sub) {
                   NSDictionary *p = [f objectForKey:@"subscriber"];
                   Person *person = [[[Person alloc] initWithProperties:p source:dataSource] autorelease];
                   [results addObject:person];
               }
               return [(NSDictionary *)jsonValue objectForKey:@"nextPageUrl"];               
           }];
    
    following = [[PersonList alloc] initWithCollectionView:followingCV basePath:@"chatter/users/me/following" source:src
           factory:^NSString *(NSUInteger httpStatusCode, NSObject *jsonValue, NSMutableArray *results) {
               NSArray *sub = [(NSDictionary *)jsonValue objectForKey:@"following"];
               for (NSDictionary *f in sub) {
                   NSDictionary *p = [f objectForKey:@"subject"];
                   if ([[p objectForKey:@"type"] isEqualToString:@"User"]) {
                       Person *person = [[[Person alloc] initWithProperties:p source:dataSource] autorelease];
                       [results addObject:person];
                   }
               }
               return [(NSDictionary *)jsonValue objectForKey:@"nextPageUrl"];               
           }];
}

@end

@interface PersonList ()
@property (nonatomic, retain, readwrite) NSArray *items;
@property (nonatomic, retain, readwrite) NSString *nextPageUrl;
@property (copy) PersonFactory personFactoryBlock;
@end

@implementation PersonList

@synthesize items, nextPageUrl, personFactoryBlock;

+(NSSet *)keyPathsForValuesAffectingHasNextPage {
    return [NSSet setWithObject:@"nextPageUrl"];
}

-(id)initWithCollectionView:(CollectionViewPeople *)cv basePath:(NSString *)base source:(FeedDataSource *)source  factory:(PersonFactory)f {
    self = [super init];
    [self setPersonFactoryBlock:f];
    collectionView = [cv retain];
    dataSource = [source retain];
    basePath = [base retain];
    nextPageItem = [[LoadOlder alloc] initWithController:self];
    [self performFetch:nil];
    return self;
}

-(void)dealloc {
    [dataSource release];
    [collectionView release];
    [items release];
    [basePath release];
    [personFactoryBlock release];
    [nextPageItem release];
    [super dealloc];
}

-(void)performFetch:(NSString *)searchTerm {
    NSString *path = basePath;
    if ([searchTerm length] >= 2) {
        path = [NSString stringWithFormat:@"%@?q=%@", basePath, [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    [dataSource fetchJsonPath:path done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        NSMutableArray *results = [NSMutableArray array];
        NSString *nextPage = personFactoryBlock(httpStatusCode, jsonValue, results);
        [self setNextPageUrl:nextPage];
        if ([self hasNextPage])
            [results addObject:nextPageItem];
        [self setItems:results];
        [collectionView setContent:items];
        
    } runOnMainThread:YES];
}

-(void)loadOlderRows:(id)sender {
    [self fetchNextPage];
}

-(void)fetchNextPage {
    [dataSource fetchJsonPath:nextPageUrl done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        NSMutableArray *results = [NSMutableArray arrayWithArray:items];
        if ([results lastObject] == nextPageItem)
            [results removeLastObject];
        NSString *nextPage = personFactoryBlock(httpStatusCode, jsonValue, results);
        [self setNextPageUrl:nextPage];
        if ([self hasNextPage])
            [results addObject:nextPageItem];
        [self setItems:results];
        [collectionView setContent:items];
        
    } runOnMainThread:YES];
}

-(BOOL)hasNextPage {
    return [nextPageUrl length] > 0;
}

-(void)setNextPageUrl:(NSString *)p {
    [nextPageUrl autorelease];
    nextPageUrl = ((NSObject *)p) == [NSNull null] ? nil : [p retain];
}

@end

@implementation Person

@synthesize actorPhoto;

-(id)initWithProperties:(NSDictionary *)p source:(FeedDataSource *)src {
    self = [super init];
    props = [p retain];
    [src fetchImagePath:[p valueForKeyPath:@"photo.smallPhotoUrl"] done:^(NSUInteger httpStatusCode, NSImage *image) {
        self.actorPhoto = image;
    } runOnMainThread:YES];
    return self;
}

-(void)dealloc {
    [props release];
    [actorPhoto release];
    [super dealloc];
}

-(id)valueForUndefinedKey:(NSString *)key {
    id v =  [props valueForKey:key];
    return v == [NSNull null] ? nil : v;
}

@end