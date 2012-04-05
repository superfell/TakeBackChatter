//
//  FeedDataSource.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>
#import "UrlConnectionDelegate.h"

@class ZKSforceClient;
@class CollectionViewFeed;
@class FeedItem;
@class Feed;

typedef void (^ImageUrlCompletionBlock)(NSUInteger httpStatusCode, NSImage *image);

@interface FeedDataSource : NSObject {
    ZKSforceClient  *sforce;
    Feed            *feed;
    NSArray         *feeds;
}

-(id)initWithSforceClient:(ZKSforceClient *)c;

-(NSArray *)feeds;    // of Feed

@property (retain) Feed *feed;

@property (readonly) NSURL *serverUrl;
@property (readonly) NSString *sessionId;

@property (readonly) NSString *userId;
@property (readonly) NSString *userName;

-(void)updateStatus:(NSString *)newStatus;
-(void)createContentPost:(NSString *)postText content:(NSData *)content contentName:(NSString *)name;
-(void)downloadContentFor:(FeedItem *)feedItem;

-(void)fetchJsonUrl:(NSURL *)url done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain;
-(void)fetchJsonPath:(NSString *)path done:(JsonUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain;
-(void)fetchImageUrl:(NSURL *)url done:(ImageUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain;
-(void)fetchImagePath:(NSString *)path done:(ImageUrlCompletionBlock)doneBlock runOnMainThread:(BOOL)runOnMain;

@property (readonly) NSString *defaultWindowTitle;
@property (readonly) NSString *defaultWindowAutosaveName;

@end
