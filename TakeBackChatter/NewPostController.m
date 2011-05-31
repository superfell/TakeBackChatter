//
//  NewPostController.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import "NewPostController.h"
#import "NSArray_extras.h"
#import "zkSforce.h"
#import "FeedDataSource.h"

@interface NewPostController ()
@property (retain, nonatomic, readwrite) NSImage *attachmentIcon;
@property (retain) NSData  *attachmentData;
@end

@implementation NewPostController

@synthesize postText, window;
@synthesize attachmentFilename, attachmentData, attachmentIcon;

+(NSSet *)keyPathsForValuesAffectingCanEditFilename {
    return [NSSet setWithObject:@"attachmentData"];
}

+(NSSet *)keyPathsForValuesAffectingAttachmentIcon {
    return [NSSet setWithObject:@"attachmentFilename"];
}

+(NSSet *)keyPathsForValuesAffectingCanCreate {
    return [NSSet setWithObjects:@"postText", @"attachmentData", @"attachmentFilename", nil];
}

- (id)initFor:(FeedDataSource *)feed {
    self = [super init];
    feedDataSource = [feed retain];
    [NSBundle loadNibNamed:@"NewPost" owner:self];
    [window setTitle:feedDataSource.defaultWindowTitle];
    [window setFrameAutosaveName:[NSString stringWithFormat:@"%@ / %@", feedDataSource.defaultWindowAutosaveName, @"NewPost"]];
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
    [attachmentData release];
    [attachmentFilename release];
    [attachmentIcon release];
    [super dealloc];
}

-(IBAction)pasteFromClipboard:(id)sender {
    NSPasteboard *p = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray arrayWithObject:[NSString class]];
    NSArray *items = [p readObjectsForClasses:types options:[NSDictionary dictionary]];
    if (items != nil && items.count > 0) {
        self.postText = [items firstObject];
        return;
    }
    types = [NSArray arrayWithObject:[NSImage class]];
    items = [p readObjectsForClasses:types options:[NSDictionary dictionary]];
    if (items != nil && items.count > 0) {
        NSImage *i = [items firstObject];
        NSImageRep *pref = nil;
        double prefScore = 0;
        for (NSImageRep *ir in [i representations]) {
            if (![ir isKindOfClass:[NSBitmapImageRep class]]) continue;
            double s = [ir pixelsHigh] * [ir pixelsWide] * [ir bitsPerSample];
            if (s > prefScore) {
                prefScore = s;
                pref = ir;
            }
        }
        if (pref) {
            NSData *image = [(NSBitmapImageRep *)pref representationUsingType:NSPNGFileType properties:nil];
            if (image) {
                self.attachmentData = image;
                self.attachmentIcon = i;
                self.attachmentFilename = @"";
            }
        }
    }
}

-(IBAction)create:(id)sender {
    if ([attachmentFilename length] == 0 && attachmentData == nil)
        [feedDataSource updateStatus:postText];
    else {
        NSData *data = self.attachmentData != nil ? self.attachmentData : [NSData dataWithContentsOfFile:attachmentFilename];
        NSString *dataName = self.attachmentFilename;
        if (self.attachmentData == nil) {
            dataName = [dataName lastPathComponent];
        } else {
            if (![[dataName lowercaseString] hasSuffix:@".png"])
                dataName = [dataName stringByAppendingString:@".png"];
        }
        [feedDataSource createContentPost:postText content:data contentName:dataName];
    }    
    [window close];
}

-(IBAction)attachFile:(id)sender {
    NSOpenPanel *p = [NSOpenPanel openPanel];
    [p setCanChooseDirectories:NO];
    [p setAllowsMultipleSelection:NO];
    [p setCanChooseFiles:YES];
    [p beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) return;
        self.attachmentIcon = [[[NSWorkspace sharedWorkspace] iconForFile:[[p URL] path]] retain];
        self.attachmentFilename = [[p URL] path];
        self.attachmentData= nil;
    }];
}

-(BOOL)canCreate {
    return (postText.length > 0) && 
        ((self.attachmentData == nil) || (self.attachmentFilename.length> 0));
}

-(BOOL)canEditFilename {
    return self.attachmentData != nil;
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
