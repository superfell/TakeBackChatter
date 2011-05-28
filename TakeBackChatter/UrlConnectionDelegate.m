//
//  UrlConnectionDelegate.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import "UrlConnectionDelegate.h"

@implementation UrlConnectionDelegate

@synthesize data, response;

-(void)dealloc {
    [response release];
    [data release];
    [super dealloc];
}

-(NSUInteger)httpStatusCode {
    return [self.response statusCode];
}

// start collecting up the response data.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse {
    self.response = (NSHTTPURLResponse *)urlResponse;
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    [self.data appendData:d];
}

// we've gotten all the response data, run the completion block.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // subclasses should implmement
}

@end

@implementation UrlConnectionDelegateWithBlock

@synthesize completionBlock, runBlockOnMainThread;

+(id)urlDelegateWithBlock:(UrlCompletionBlock) doneBlock runOnMainThread:(BOOL)useMain {
    UrlConnectionDelegateWithBlock *d = [[UrlConnectionDelegateWithBlock alloc] init];
    d.completionBlock = doneBlock;
    d.runBlockOnMainThread = useMain;
    return [d autorelease];
}

-(void)dealloc {
    [completionBlock release];
    [super dealloc];
}

// we've gotten all the response data, run the completion block.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // which thread/queue do we want to run the completion block on.
    dispatch_queue_t queue = self.runBlockOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^(void) {
        self.completionBlock(self.httpStatusCode, self.response, self.data, nil);
    });
}

@end