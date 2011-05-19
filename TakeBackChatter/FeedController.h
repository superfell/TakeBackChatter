//
//  FeedController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSforceClient;

@interface FeedController : NSObject {
        
}

@property (retain) NSArray *feedItems;
@property (nonatomic, retain) ZKSforceClient *sforce;
@end
