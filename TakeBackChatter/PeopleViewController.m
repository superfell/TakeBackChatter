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

@synthesize followingCV, followersCV, allCV, dataSource, following, followers, all;

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

-(NSArray *)followers {
    if (followers == nil) {
        [dataSource fetchJsonPath:@"chatter/users/me/followers" done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
            NSArray *sub = [(NSDictionary *)jsonValue objectForKey:@"followers"];
            NSMutableArray *res = [NSMutableArray arrayWithCapacity:[sub count]];
            for (NSDictionary *f in sub) {
                NSDictionary *p = [f objectForKey:@"subscriber"];
                Person *person = [[[Person alloc] initWithProperties:p source:dataSource] autorelease];
                [res addObject:person];
            }
            
            followers = [res retain];
            [followersCV setContent:followers];
        } runOnMainThread:YES];
    }
    return followers;
}

-(NSArray *)following {
    if (following == nil) {
        [dataSource fetchJsonPath:@"chatter/users/me/following" done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
            NSArray *sub = [(NSDictionary *)jsonValue objectForKey:@"following"];
            NSMutableArray *res = [NSMutableArray arrayWithCapacity:[sub count]];
            for (NSDictionary *f in sub) {
                NSDictionary *p = [f objectForKey:@"subject"];
                if ([[p objectForKey:@"type"] isEqualToString:@"User"]) {
                    Person *person = [[[Person alloc] initWithProperties:p source:dataSource] autorelease];
                    [res addObject:person];
                }
            }
            
            following = [res retain];
            [followingCV setContent:following];
        } runOnMainThread:YES];
    }
    return followers;
}

-(void)fetchUsers:(NSString *)searchTerm {
    NSString *path = @"chatter/users";
    if ([searchTerm length] >= 2) {
        path = [NSString stringWithFormat:@"chatter/users?q=%@", [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    [dataSource fetchJsonPath:path done:^(NSUInteger httpStatusCode, NSObject *jsonValue) {
        NSArray *users = [(NSDictionary *)jsonValue objectForKey:@"users"];
        NSMutableArray *res = [NSMutableArray arrayWithCapacity:[users count]];
        for (NSDictionary *u in users) {
            Person *person = [[[Person alloc] initWithProperties:u source:dataSource] autorelease];
            [res addObject:person];
        }
        all = [res retain];
        [allCV setContent:all];
        
    } runOnMainThread:YES];
}

-(IBAction)searchPeople:(id)sender {
    [all autorelease];
    [self fetchUsers:[sender stringValue]];
}

-(NSArray *)all {
    if (all == nil) {
        [self fetchUsers:nil];
    }
    return all;
}

-(void)setDataSource:(FeedDataSource *)src {
    [dataSource autorelease];
    dataSource = [src retain];
    [following release];
    [followers release];
    [self following];
    [self followers];
    [self all];
    [followingCV setDefaultProperties];
    [followersCV setDefaultProperties];
    [allCV setDefaultProperties];
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