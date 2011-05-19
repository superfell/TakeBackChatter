//
//  ZKSObject_KVO.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "ZKSObject_KVO.h"

@implementation ZKSObject (ZKSObject_KVO)

- (id)valueForUndefinedKey:(NSString *)key
{
	id v = [fields objectForKey:key];
	if (v != nil) {
		return v == [NSNull null] ? nil : v;
	}
	return [super valueForUndefinedKey:key];
}

@end

