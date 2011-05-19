//
//  FeedItem.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSObject;

@interface FeedItem : NSObject {
    ZKSObject  *row;
}

+(id)feedItemFrom:(ZKSObject *)row;

@property (readonly) NSString *title;
@property (readonly) NSString *body;

@end
