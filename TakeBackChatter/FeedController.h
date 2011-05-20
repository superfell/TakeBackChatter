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

@property (nonatomic, retain) NSArray *feedItems;
@property (nonatomic, assign) BOOL hasMore;

@property (nonatomic, retain) ZKSforceClient *sforce;

-(IBAction)loadNextPage:(id)sender;

@end
