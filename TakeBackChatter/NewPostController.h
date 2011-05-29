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
    NSString        *attachmentFilename;
    NSWindow        *window;
}

+(id)postControllerFor:(FeedDataSource *)feed;

-(IBAction)create:(id)sender;
-(IBAction)attachFile:(id)sender;

@property (retain) IBOutlet NSWindow *window;
@property (retain) NSString *postText;
@property (retain) NSString *attachmentFilename;

@property (readonly) BOOL canCreate;

@end
