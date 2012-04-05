//
//  PeopleViewController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 3/27/12.
//

#import "PeopleViewController.h"
#import "FeedDataSource.h"
#import "CollectionViews.h"

@implementation PeopleViewController

@synthesize collectionView, dataSource, following;

-(void)dealloc {
    [dataSource release];
    [collectionView release];
    [following release];
    [super dealloc];
}

-(NSArray *)following {
    if (following == nil) {
        [dataSource fetchJsonPath:@"chatter/users/me/followers" done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
            NSArray *sub = [(NSDictionary *)jsonValue objectForKey:@"followers"];
            NSMutableArray *res = [NSMutableArray arrayWithCapacity:[sub count]];
            for (NSDictionary *f in sub) {
                NSDictionary *p = [f objectForKey:@"subscriber"];
                Person *person = [[[Person alloc] initWithProperties:p source:dataSource] autorelease];
                [res addObject:person];
            }
            
            following = [res retain];
            [collectionView setContent:following];
        } runOnMainThread:YES];
    }
    return following;
}

-(void)setDataSource:(FeedDataSource *)src  {
    [dataSource autorelease];
    dataSource = [src retain];
    [following release];
    [self following];
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