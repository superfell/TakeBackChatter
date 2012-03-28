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
            following = [sub retain];
            NSLog(@"followers %@", following);
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
