//
//  UrlConnectionDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import <Foundation/Foundation.h>


typedef void (^UrlCompletionBlock)(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err);

@interface UrlConnectionDelegateWithBlock : NSObject {
    UrlCompletionBlock  completionBlock;
    NSMutableData       *data;
    NSHTTPURLResponse   *response;
    BOOL                runBlockOnMainThread;
    NSUInteger          httpStatusCode;
}

+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock runOnMainThread:(BOOL)useMain;

@property (copy) UrlCompletionBlock  completionBlock;
@property (retain) NSMutableData     *data;
@property (retain) NSHTTPURLResponse *response;
@property (assign) BOOL              runBlockOnMainThread;
@property (assign) NSUInteger        httpStatusCode;

@end