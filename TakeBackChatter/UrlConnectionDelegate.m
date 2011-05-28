//
//  UrlConnectionDelegate.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import "UrlConnectionDelegate.h"

@implementation UrlConnectionDelegate

@synthesize completionBlock, data, response;
@synthesize runBlockOnMainThread, httpStatusCode;

+(id)urlDelegateWithBlock:(UrlCompletionBlock) doneBlock runOnMainThread:(BOOL)useMain {
    UrlConnectionDelegate *d = [[UrlConnectionDelegate alloc] init];
    d.completionBlock = doneBlock;
    d.runBlockOnMainThread = useMain;
    return [d autorelease];
}

-(void)dealloc {
    [completionBlock release];
    [data release];
    [response release];
    [super dealloc];
}

// start collecting up the response data.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse {
    self.response = (NSHTTPURLResponse *)urlResponse;
    self.httpStatusCode = [self.response statusCode];
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    [self.data appendData:d];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cr {
    // indicate that this response can be cached on disk.
    NSCachedURLResponse *r = [[[NSCachedURLResponse alloc] initWithResponse:[cr response] 
                                                                       data:[cr data] 
                                                                   userInfo:[cr userInfo] 
                                                              storagePolicy:NSURLCacheStorageAllowed] autorelease];
    return r;
}

// we've gotten all the response data, run the completion block.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // which thread/queue do we want to run the completion block on.
    dispatch_queue_t queue = self.runBlockOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // once we've called the block, we're all done, so we can release ourselves and cleanup.
    dispatch_async(queue, ^(void) {
        self.completionBlock(self.httpStatusCode, self.response, self.data, nil);
    });
}

@end