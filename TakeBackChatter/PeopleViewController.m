//
//  PeopleViewController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 3/27/12.
//

#import "PeopleViewController.h"

@implementation PeopleViewController

@synthesize collectionView, dataSource;

-(void)dealloc {
    [dataSource release];
    [collectionView release];
    [super dealloc];
}

@end
