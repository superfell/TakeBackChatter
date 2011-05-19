//
//  TakeBackChatterAppDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import <Cocoa/Cocoa.h>

@class FeedController;

@interface TakeBackChatterAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet FeedController *feedController;


@end
