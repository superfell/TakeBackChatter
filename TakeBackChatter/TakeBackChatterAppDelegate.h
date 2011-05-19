//
//  TakeBackChatterAppDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//  Copyright 2011 Salesforce.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TakeBackChatterAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
