//
//  NewPostController.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import <Foundation/Foundation.h>

@class FeedDataSource;

@interface NewPostController : NSObject {
    FeedDataSource  *feedDataSource;
    NSString        *postText;
    NSData          *attachmentData;
    NSString        *attachmentFilename;
    NSImage         *attachmentIcon;
    NSWindow        *window;
}

+(id)postControllerFor:(FeedDataSource *)feed;

-(IBAction)create:(id)sender;
-(IBAction)attachFile:(id)sender;
-(IBAction)pasteFromClipboard:(id)sender;

@property (retain) IBOutlet NSWindow *window;
@property (retain) NSString *postText;
@property (retain) NSString *attachmentFilename;
@property (retain, nonatomic, readonly) NSImage *attachmentIcon;

@property (readonly) BOOL canCreate;
@property (readonly) BOOL canEditFilename;

@end
