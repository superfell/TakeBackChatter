//
//  FeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedItem.h"
#import "FeedDataSource.h"
#import "ZKSObject.h"
#import "zkQueryResult.h"
#import "NSString_extras.h"
#import "TakeBackChatterAppDelegate.h"
#import <BayesianKit/BayesianKit.h>

@implementation FeedItem

@synthesize feedItemType, actorPhotoUrl, actorPhoto, feedDataSource;

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

- (id)initWithRow:(ZKSObject *)r dataSource:(FeedDataSource *)s {
    self = [super init];
    row = [r retain];
    feedDataSource = [s retain];    // sigh, TODO fix retain loop
    feedItemType = [self resolveType];
    return self;
}

- (void)dealloc {
    [row release];
    [actorPhotoUrl release];
    [actorPhoto release];
    [contentIcon release];
    [super dealloc];
}

+(id)feedItemFrom:(ZKSObject *)row dataSource:(FeedDataSource *)src {
    return [[[FeedItem alloc] initWithRow:row dataSource:src] autorelease];
}

-(NSString *)quantity:(int)q singluar:(NSString *)s plural:(NSString *)p {
    return [NSString stringWithFormat:@"%d %@", q, q == 1 ? s : p];
}

-(NSString *)rowId {
    return [row id];
}

-(NSString *)actor {
    return [row valueForKeyPath:@"CreatedBy.Name"];
}

-(NSString *)actorId {
    return [row valueForKey:@"CreatedById"];
}

-(NSDate *)createdDate {
    return [row dateTimeValue:@"CreatedDate"];
}

-(NSString *)type {
    return [row valueForKey:@"Type"];
}

-(NSString *)title {
    NSString *actor = [self actor];
    NSString *name = [row valueForKeyPath:@"Parent.Name"];
    switch (self.feedItemType) {
        case FeedTypeUserStatus: return name;
        case FeedTypeTextPost:
        case FeedTypeLinkPost:
        case FeedTypeContentPost: return [actor isEqualToString:name] ? actor : [NSString stringWithFormat:@"%@ to %@", actor, name];
        case FeedTypeTrackedChange: return [NSString stringWithFormat:@"%@ - %@", name, actor];
    }
    return name;
}

-(NSString *)contentTitle {
    return [row valueForKeyPath:@"FeedPost.Title"];
}

-(NSImage *)contentIcon {
    if (contentIcon == nil) {
        NSString *mimeType = [row valueForKeyPath:@"FeedPost.ContentType"];
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)mimeType, NULL);
        if (uti == nil)
            NSLog(@"Unable to find a UTI for %@", mimeType);
        else {
            contentIcon = [[[NSWorkspace sharedWorkspace] iconForFileType:(NSString*)uti] retain];
            CFRelease(uti);
        }
    }
    return contentIcon;
}

-(NSAttributedString *)linkPostBody {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
    [s beginEditing];
    NSString *body = [row valueForKeyPath:@"FeedPost.Body"];
    NSString *title = [row valueForKeyPath:@"FeedPost.Title"];
    NSString *link = [row valueForKeyPath:@"FeedPost.LinkUrl"];
    if (body.length > 0) {
        [s appendAttributedString:[body attributedString]];
        [s appendAttributedString:[@"\r" attributedString]];
    }
    if (title.length > 0) {
        [s appendAttributedString:[title attributedString]];
        [s appendAttributedString:[@"\r" attributedString]];
    }
    if (link.length > 0) {
        NSURL *url = [NSURL URLWithString:link];
        if (url != nil)
            [s appendAttributedString:[NSAttributedString hyperlinkFromString:link withURL:url]];
        else
            [s appendAttributedString:[link attributedString]];
    }
    [s endEditing];
    return [s autorelease];
}

-(NSObject *)body {
    switch (self.feedItemType) {
        case FeedTypeUserStatus:
        case FeedTypeTextPost:
        case FeedTypeContentPost:
            return [row valueForKeyPath:@"FeedPost.Body"];
        case FeedTypeLinkPost:
            return [self linkPostBody];
        case FeedTypeTrackedChange:
            return [NSString stringWithFormat:@"made %@", 
                    [self quantity:[[row queryResultValue:@"FeedTrackedChanges"] size] singluar:@"change" plural:@"changes"]];
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
    return [self quantity:count singluar:@"comment" plural:@"comments"];
}

-(NSString *)age {
    NSDate *created = [row dateTimeValue:@"CreatedDate"];
    NSTimeInterval age = abs([created timeIntervalSinceNow]);
    if (age < 3600) return [self quantity:(int)(age/60) singluar:@"min" plural:@"mins"];
    age = age / 3600;
    if (age < 24) return [self quantity:(int)age singluar:@"hour" plural:@"hours"];
    return [self quantity:(int)(age/24) singluar:@"day" plural:@"days"];
}

-(NSString *)classificationText {
    return [NSString stringWithFormat:@"%@ %@", self.title, self.body];
}

-(int)chanceIsJunk {
    NSDictionary *cl = [[[NSApp delegate] classifier] guessWithString:self.classificationText];
    NSNumber *g = [cl objectForKey:@"Junk"];
    return [g floatValue] *100;
}

@end
