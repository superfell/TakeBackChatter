//
//  FeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedItem.h"
#import "ZKSObject.h"
#import "zkQueryResult.h"
#import "NSString_extras.h"
#import "TakeBackChatterAppDelegate.h"
#import <BayesianKit/BayesianKit.h>

@implementation FeedItem

@synthesize feedItemType, actorPhotoUrl, actorPhoto;

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
    feedItemType = [self resolveType];
    return self;
}

- (void)dealloc {
    [row release];
    [actorPhotoUrl release];
    [actorPhoto release];
    [super dealloc];
}

+(id)feedItemFrom:(ZKSObject *)row {
    return [[[FeedItem alloc] initWithRow:row] autorelease];
}

-(NSString *)quantity:(int)q singluar:(NSString *)s plural:(NSString *)p {
    return [NSString stringWithFormat:@"%d %@", q, q == 1 ? s : p];
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

-(NSAttributedString *)linkPostBody {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
    [s beginEditing];
    [s appendAttributedString:[NSAttributedString attributedStringWithString:[row valueForKeyPath:@"FeedPost.Body"]]];
    [s appendAttributedString:[NSAttributedString attributedStringWithString:@"\r"]];
    [s appendAttributedString:[NSAttributedString attributedStringWithString:[row valueForKeyPath:@"FeedPost.Title"]]];
    [s appendAttributedString:[NSAttributedString attributedStringWithString:@"\r"]];

    NSString *url = [row valueForKeyPath:@"FeedPost.LinkUrl"];
    [s appendAttributedString:[NSAttributedString hyperlinkFromString:url withURL:[NSURL URLWithString:url]]];

     [s endEditing];
    return s;
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
