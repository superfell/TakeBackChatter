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

@synthesize completionBlock;

+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock queue:(dispatch_queue_t)queue {
    UrlConnectionDelegateWithBlock *d = [[UrlConnectionDelegateWithBlock alloc] init];
    d.completionBlock = doneBlock;
    d->queueToRunBlock = queue;
    return [d autorelease];
}

+(id)urlDelegateWithBlock:(UrlCompletionBlock) doneBlock runOnMainThread:(BOOL)useMain {
    dispatch_queue_t q = useMain ? dispatch_get_main_queue() : dispatch_get_current_queue();
    return [self urlDelegateWithBlock:doneBlock queue:q];
}

-(void)dealloc {
    [completionBlock release];
    [super dealloc];
}

// we've gotten all the response data, run the completion block.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    dispatch_async(queueToRunBlock, ^(void) {
        self.completionBlock(self.httpStatusCode, self.response, self.data, nil);
    });
}

@end