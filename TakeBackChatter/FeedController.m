//
//  FeedController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "FeedController.h"
#import "zkSforce.h"

@implementation FeedController

@synthesize feedItems=_feedItems, sforce=_sforce;

-(void)startQuery {
    NSString *soql = @"SELECT Id, Type, CreatedDate, CreatedById, CreatedBy.Name, " \
        "ParentId, Parent.Name, FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.LinkUrl, " \
           "(SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges), " \
           "(SELECT Id, CreatedDate, CreatedById, CreatedBy.Name, CommentBody FROM FeedComments ORDER BY CreatedDate DESC) " \
        "FROM NewsFeed ORDER BY CreatedDate DESC, Id DESC LIMIT 10";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ZKQueryResult *qr = [self.sforce query:soql];
        NSLog(@"results : %@", qr);
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.feedItems = [qr records];
            for (ZKSObject *f in self.feedItems)
                NSLog(@"%@ %@ %@", f.id, [f fieldValue:@"Type"], [[f fieldValue:@"Parent"] fieldValue:@"Name"]);
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
