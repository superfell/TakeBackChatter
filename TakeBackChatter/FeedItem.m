//
//  FeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedItem.h"
#import "ZKSObject.h"
#import "zkQueryResult.h"

@implementation FeedItem

@synthesize feedItemType = _feedItemType, actorPhotoUrl=_actorPhotoUrl;

// This tells KVO (and theirfore the UI binding), that the 'ActorPhoto' property value is affected by changes to the 'ActorPhotoUrl' property
+(NSSet *)keyPathsForValuesAffectingActorPhoto {
    return [NSSet setWithObject:@"actorPhotoUrl"];
}

- (FeedItemType)resolveType {
    NSString *t = self.type;
    if ([t isEqualToString:@"UserStatus"])
        return FeedTypeUserStatus;
    if ([t isEqualToString:@"TextPost"])
        return FeedTypeTextPost;
    if ([t isEqualToString:@"LinkPost"])
        return FeedTypeLinkPost;
    if ([t isEqualToString:@"ContentPost"])
        return FeedTypeContentPost;
    if ([t isEqualToString:@"TrackedChange"])
        return FeedTypeTrackedChange;
    NSLog(@"got unexpected type of %@", t);
    return FeedTypeUserStatus;
}

- (id)initWithRow:(ZKSObject *)r {
    self = [super init];
    row = [r retain];
    _feedItemType = [self resolveType];
    return self;
}

- (void)dealloc {
    [row release];
    [_actorPhotoUrl release];
    [super dealloc];
}

+(id)feedItemFrom:(ZKSObject *)row {
    return [[[FeedItem alloc] initWithRow:row] autorelease];
}

-(NSString *)actor {
    return [row valueForKeyPath:@"CreatedBy.Name"];
}

-(NSString *)actorId {
    return [row valueForKey:@"CreatedById"];
}

-(NSImage *)actorPhoto {
    NSLog(@"actorPhoto called, url=%@", self.actorPhotoUrl);
    if (self.actorPhotoUrl == nil) return nil;
    return [[[NSImage alloc] initWithContentsOfURL:self.actorPhotoUrl] autorelease];
}

-(NSString *)type {
    return [row valueForKey:@"Type"];
}

-(NSString *)title {
    return [row valueForKeyPath:@"Parent.Name"];
}

-(NSString *)body {
    switch (self.feedItemType) {
        case FeedTypeUserStatus:
        case FeedTypeTextPost:
        case FeedTypeLinkPost:
        case FeedTypeContentPost:
            return [row valueForKeyPath:@"FeedPost.Body"];
        case FeedTypeTrackedChange:
            return [NSString stringWithFormat:@"made %d changes", [[row queryResultValue:@"FeedTrackedChanges"] size]];
    }
}

-(int)commentCount {
    return [[row queryResultValue:@"FeedComments"] size];
}

-(NSArray *)comments {
    return [[row queryResultValue:@"FeedComments"] records];
}

-(NSString *)commentsLabel {
    int count = self.commentCount;
    if (count == 0) return @"";
    if (count == 1) return @"1 comment";
    return [NSString stringWithFormat:@"%d comments", count];
}

-(NSString *)age {
    NSDate *created = [row dateTimeValue:@"CreatedDate"];
    NSTimeInterval age = abs([created timeIntervalSinceNow]);
    if (age < 60) return @"1m";
    if (age < 3600) return [NSString stringWithFormat:@"%dm", (int)(age / 60)];
    age = age / 3600;
    if (age < 24) return [NSString stringWithFormat:@"%dh", (int)age];
    return [NSString stringWithFormat:@"%dd", (int)(age / 24)];
}

@end
