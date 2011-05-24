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
    NSMenuItem      *loginMenu, *logoutMenu;
    NSMutableArray  *feedControllers;
}

@property (readonly) BKClassifier *classifier;

@property (assign) IBOutlet NSMenuItem *loginMenu;
@property (assign) IBOutlet NSMenuItem *logoutMenu;

-(IBAction)startLogin:(id)sender;
-(IBAction)logout:(id)sender;

@end
