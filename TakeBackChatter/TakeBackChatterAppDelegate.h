//
//  TakeBackChatterAppDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Cocoa/Cocoa.h>

@class FeedController;
@class Categorizer;
@class ZKLoginController;

@interface TakeBackChatterAppDelegate : NSObject <NSApplicationDelegate> {
    Categorizer       *categorizer;
    NSMenuItem        *loginMenu, *logoutMenu;
    NSMutableArray    *feedControllers;
    ZKLoginController *loginController;
    NSWindow          *welcomeWindow;
}

@property (readonly) Categorizer *categorizer;

@property (assign) IBOutlet NSMenuItem *loginMenu;
@property (assign) IBOutlet NSMenuItem *logoutMenu;
@property (assign) IBOutlet NSWindow *welcomeWindow;

-(IBAction)startLogin:(id)sender;
-(IBAction)logout:(id)sender;

@end
