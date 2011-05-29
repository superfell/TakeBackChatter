//
//  NewPostController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import "NewPostController.h"
#import "zkSforce.h"
#import "FeedDataSource.h"

@implementation NewPostController

@synthesize postText, attachmentFilename;
@synthesize window;

+(NSSet *)keyPathsForValuesAffectingCanCreate {
    return [NSSet setWithObject:@"postText"];
}

- (id)initFor:(FeedDataSource *)feed {
    self = [super init];
    feedDataSource = [feed retain];
    [NSBundle loadNibNamed:@"NewPost" owner:self];
    return self;
}

+(id)postControllerFor:(FeedDataSource *)feed {
    return [[[self alloc] initFor:feed] autorelease];
}

- (void)dealloc {
    NSLog(@"newPostController dealloc");
    [window release];
    [feedDataSource release];
    [postText release];
    [attachmentFilename release];
    [super dealloc];
}

-(IBAction)create:(id)sender {
    if ([attachmentFilename length] == 0)
        [feedDataSource updateStatus:postText];
    [window close];
}

-(IBAction)attachFile:(id)sender {
}

-(BOOL)canCreate {
    return [postText length] > 0;
}

-(void)windowWillClose:(id)sender {
    NSLog(@"windowWillClose");
    [window setDelegate:nil];
    [window release];
    window = nil;
    [self release];
}

@end
