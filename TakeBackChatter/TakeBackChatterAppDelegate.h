//
//  TakeBackChatterAppDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Cocoa/Cocoa.h>

@class FeedController;
@class BKClassifier;

@interface TakeBackChatterAppDelegate : NSObject <NSApplicationDelegate> {
@private
    BKClassifier    *classifier;
    NSWindow        *window;
    NSMenuItem      *loginMenu, *logoutMenu;
    FeedController  *feedController;
}

@property (readonly) BKClassifier *classifier;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenuItem *loginMenu;
@property (assign) IBOutlet NSMenuItem *logoutMenu;

@property (assign) IBOutlet FeedController *feedController;

-(IBAction)startLogin:(id)sender;
-(IBAction)logout:(id)sender;

@end
