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

+(NSSet *)keyPathsForValuesAffectingAttachmentIcon {
    return [NSSet setWithObject:@"attachmentFilename"];
}

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
    [attachmentIcon release];
    [super dealloc];
}

-(IBAction)create:(id)sender {
    if ([attachmentFilename length] == 0)
        [feedDataSource updateStatus:postText];
    else
        [feedDataSource createContentPost:postText withFile:attachmentFilename];
    
    [window close];
}

-(IBAction)attachFile:(id)sender {
    NSOpenPanel *p = [NSOpenPanel openPanel];
    [p setCanChooseDirectories:NO];
    [p setAllowsMultipleSelection:NO];
    [p setCanChooseFiles:YES];
    [p beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) return;
        [attachmentIcon autorelease];
        attachmentIcon = [[[NSWorkspace sharedWorkspace] iconForFile:[[p URL] path]] retain];
        self.attachmentFilename = [[p URL] path];
    }];
}

-(BOOL)canCreate {
    return [postText length] > 0;
}

-(NSImage *)attachmentIcon {
    return attachmentIcon != nil ? attachmentIcon : [NSImage imageNamed:NSImageNameMultipleDocuments];
}

-(void)windowWillClose:(id)sender {
    NSLog(@"windowWillClose");
    [window setDelegate:nil];
    [window release];
    window = nil;
    [self release];
}

@end
