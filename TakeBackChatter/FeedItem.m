//
//  FeedItem.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedItem.h"
#import "FeedDataSource.h"
#import "NSString_extras.h"
#import "TakeBackChatterAppDelegate.h"
#import "Categorizer.h"
#import "UrlConnectionDelegate.h"

static NSDateFormatter *dateFormatter, *dateTimeFormatter;

@implementation FeedItem

@synthesize feedItemType, actorPhotoUrl, actorPhoto, feedDataSource;

+(void)initialize {
	dateTimeFormatter = [[NSDateFormatter alloc] init];
	[dateTimeFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSZ"];
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
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

-(id)initWithFeedItem:(NSDictionary *)feedItem dataSource:(FeedDataSource *)src {
    self = [super init];
    data = [feedItem retain];
    feedDataSource = [src retain];    // sigh, TODO fix retain loop
    feedItemType = [self resolveType];
    [self fetchActorPhoto];
    return self;
}

- (void)dealloc {
    [data release];
    [actorPhotoUrl release];
    [actorPhoto release];
    [contentIcon release];
    [super dealloc];
}

+(id)connectFeedItem:(NSDictionary *)feedItem dataSource:(FeedDataSource *)src {
    return [[[FeedItem alloc] initWithFeedItem:feedItem dataSource:src] autorelease];
}

-(NSString *)quantity:(int)q singluar:(NSString *)s plural:(NSString *)p {
    return [NSString stringWithFormat:@"%d %@", q, q == 1 ? s : p];
}

-(NSDate *)dateTimeValue:(NSString *)key {
    NSString *v = [data objectForKey:key];
    if (v == nil) return nil;
	// ok, so a little hackish, but does the job
	// note to self, make sure API always returns GMT times ;)
	NSMutableString *dt = [NSMutableString stringWithString:v];
	[dt deleteCharactersInRange:NSMakeRange([dt length] -1,1)];
	[dt appendString:@"+00"];
	return [dateTimeFormatter dateFromString:dt];
}

-(NSString *)rowId {
    return [data objectForKey:@"id"];
}

-(NSString *)actor {
    return [data valueForKeyPath:@"actor.name"];
}

-(NSString *)actorId {
    return [data valueForKeyPath:@"actor.id"];
}

-(NSURL *)actorPhotoUrl {
    NSString *photo = [data valueForKeyPath:@"actor.photo.smallPhotoUrl"];
    return [NSURL URLWithString:photo relativeToURL:feedDataSource.serverUrl];
}

-(NSDate *)createdDate {
    return [self dateTimeValue:@"createdDate"];
}

-(NSString *)type {
    return [data objectForKey:@"type"];
}

-(NSString *)title {
    NSString *actor = [self actor];
    NSString *name = [data valueForKeyPath:@"parent.name"];
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
    return [data valueForKeyPath:@"attachment.title"];
}

-(NSImage *)contentIcon {
    if (contentIcon == nil) {
        NSObject *mimeType = [data valueForKeyPath:@"attachment.mimeType"];
        if (mimeType == [NSNull null]) return nil;
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
    NSString *body = [data valueForKeyPath:@"body.text"];
    NSString *title = [data valueForKeyPath:@"attachment.title"];
    NSString *link = [data valueForKeyPath:@"attachment.url"];
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
            return [data valueForKeyPath:@"body.text"];
        case FeedTypeLinkPost:
            return [self linkPostBody];
        case FeedTypeTrackedChange:
            return [data valueForKeyPath:@"body.text"];
    }
}

-(int)commentCount {
    return [[data valueForKeyPath:@"comments.total"] intValue];
}

-(NSArray *)comments {
    return [data valueForKeyPath:@"comments.comments"];
}

-(NSString *)commentsLabel {
    int count = self.commentCount;
    if (count == 0) return @"";
    return [self quantity:count singluar:@"comment" plural:@"comments"];
}

-(NSString *)age {
    NSDate *created = [self dateTimeValue:@"createdDate"];
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
    return [[[NSApp delegate] categorizer] chanceIsJunk:self];
}

-(void)fetchActorPhoto {
    [feedDataSource fetchImageUrl:self.actorPhotoUrl done:^(NSUInteger httpStatusCode, NSImage *image) {
        self.actorPhoto = image;
    } runOnMainThread:YES];
}

@end
