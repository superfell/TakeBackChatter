//
//  NSArray_extras.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/24/11.
//

#import "NSArray_extras.h"


@implementation NSArray (NSArray_extras)

-(id)firstObject {
    return self.count == 0 ? nil : [self objectAtIndex:0];
}

@end
