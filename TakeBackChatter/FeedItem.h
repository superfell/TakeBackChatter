//
//  FeedItem.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Foundation/Foundation.h>

@class ZKSObject;

typedef enum {
    FeedTypeUserStatus,
    FeedTypeTextPost,
    FeedTypeLinkPost,
    FeedTypeContentPost,
    FeedTypeTrackedChange
} FeedItemType;

@interface FeedItem : NSObject {
    ZKSObject       *row;
    NSURL           *actorPhotoUrl;
    NSImage         *actorPhoto;
    FeedItemType    feedItemType;
}

+(id)feedItemFrom:(ZKSObject *)row;

@property (readonly) NSString *type;
@property (readonly) FeedItemType feedItemType;

@property (readonly) NSString *actor;
@property (readonly) NSString *actorId;
@property (retain) NSImage *actorPhoto;
@property (retain) NSURL *actorPhotoUrl;

@property (readonly) NSString *title;
@property (readonly) NSObject *body;            // NSString or NSAttributedString
@property (readonly) NSString *age;             // "5m", "10d", "1h" etc.
@property (readonly) NSString *commentsLabel;   // "3 comments", etc.

@property (readonly) NSDate *createdDate;

@property (readonly) int commentCount;
@property (readonly) NSArray *comments;

@property (readonly) NSString *classificationText;  // all text for this item that should be classifier (as junk/good)

@property (readonly) int chanceIsJunk;

@end
