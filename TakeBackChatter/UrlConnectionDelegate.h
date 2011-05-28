//
//  UrlConnectionDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import <Foundation/Foundation.h>

@interface UrlConnectionDelegate : NSObject {
    NSMutableData       *data;
    NSHTTPURLResponse   *response;
}

@property (retain) NSMutableData     *data;
@property (retain) NSHTTPURLResponse *response;
@property (readonly) NSUInteger      httpStatusCode;

@end

typedef void (^UrlCompletionBlock)(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err);

@interface UrlConnectionDelegateWithBlock : UrlConnectionDelegate {
    UrlCompletionBlock  completionBlock;
    BOOL                runBlockOnMainThread;
}

+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock runOnMainThread:(BOOL)useMain;

@property (copy) UrlCompletionBlock  completionBlock;
@property (assign) BOOL              runBlockOnMainThread;

@end