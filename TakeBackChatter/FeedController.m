//
//  FeedController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedController.h"
#import "zkSforce.h"
#import "FeedItem.h"

@implementation FeedController

@synthesize feedItems=_feedItems, sforce=_sforce;

-(void)startActorFetch:(NSArray *)items {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableSet *actors = [NSMutableSet set];
        for (FeedItem *i in items)
            [actors addObject:[i actorId]];
        
        NSMutableString *soql = [NSMutableString stringWithCapacity:100];
        [soql appendString:@"select id, SmallPhotoUrl from User where id in ("];
        for (NSString *actor in actors)
            [soql appendFormat:@"'%@',", actor];
        [soql deleteCharactersInRange:NSMakeRange([soql length]-1,1)];
        [soql appendString:@")"];
        
        NSLog(@"actor soql : %@", soql);
        ZKQueryResult *qr = [self.sforce query:soql];
        NSString *sid = [self.sforce.sessionId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *urls = [NSMutableDictionary dictionary];
        for (ZKSObject *r in [qr records]) 
            [urls setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@",
                             [r fieldValue:@"SmallPhotoUrl"], sid]] forKey:[r id]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            for (FeedItem *i in items) {
                [i setActorPhotoUrl:[urls objectForKey:[i actorId]]];
//                NSLog(@"photoUrl %@", [i actorPhotoUrl]);
            }
        });
    });
}

-(void)startQuery {
    NSString *soql = @"SELECT Id, Type, CreatedDate, CreatedById, CreatedBy.Name, " \
        "ParentId, Parent.Name, FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.LinkUrl, " \
           "(SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges), " \
           "(SELECT Id, CreatedDate, CreatedById, CreatedBy.Name, CommentBody FROM FeedComments ORDER BY CreatedDate DESC) " \
        "FROM NewsFeed ORDER BY CreatedDate DESC, Id DESC LIMIT 10";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ZKQueryResult *qr = [self.sforce query:soql];
        NSMutableArray *res = [NSMutableArray arrayWithCapacity:[[qr records] count]];
        for (ZKSObject *r in [qr records])
            [res addObject:[FeedItem feedItemFrom:r]];
        
        [self startActorFetch:res];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.feedItems = res;
        });
    });
}

-(void)setSforce:(ZKSforceClient *)c {
    [_sforce autorelease];
    _sforce = [c retain];
    [self startQuery];
}

-(void)dealloc {
    [_feedItems release];
    [_sforce release];
    [super dealloc];
}

@end
