//
//  FeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//  Copyright 2011 Salesforce.com. All rights reserved.
//

#import "FeedItem.h"

@implementation FeedItem

- (id)initWithRow:(ZKSObject *)r {
    self = [super init];
    row = [r retain];
    return self;
}

- (void)dealloc {
    [row release];
    [super dealloc];
}

+(id)feedItemFrom:(ZKSObject *)row {
    return [[[FeedItem alloc] initWithRow:row] autorelease];
}

-(NSString *)title {
    return [row valueForKeyPath:@"Parent.Name"];
}

-(NSString *)body {
    return [row valueForKeyPath:@"FeedPost.Body"];
}

@end
