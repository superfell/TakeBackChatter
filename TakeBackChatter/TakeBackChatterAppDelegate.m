//
//  TakeBackChatterAppDelegate.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "TakeBackChatterAppDelegate.h"
#import "zkSforceClient.h"

@implementation TakeBackChatterAppDelegate

@synthesize window, feedItems=_feedItems;

static NSString *OAUTH_CLIENTID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF0T4Kw7LW_opx3J5Tj4AizUt0an8hoogMWADGIJaqUgLkVomaqyz5RRIHD4L";
static NSString *OAUTH_CALLBACK = @"compocketsoaptakebackchatter:///oauthdone";

-(IBAction)startLogin:(id)sender {
    // build the URL to the oauth page with our client_id & callback URL set.
    NSString *login = [NSString stringWithFormat:@"https://login.salesforce.com/services/oauth2/authorize?response_type=token&client_id=%@&redirect_uri=%@",
                       [OAUTH_CLIENTID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                       [OAUTH_CALLBACK stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:login];
    
    // ask the OS to open browser to the URL
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // tell the event manager what to do when it gets asked to open a URL (the oauth completion callback) 
    // this callback URL is registered to this app in the info.plist file
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(getUrl:withReplyEvent:) 
                                                     forEventClass:kInternetEventClass 
                                                        andEventID:kAEGetURL];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
	// Now you can parse the URL and perform whatever action is needed
    
    ZKSforceClient *client = [[[ZKSforceClient alloc] init] autorelease];
    [client loginFromOAuthCallbackUrl:url oAuthConsumerKey:OAUTH_CLIENTID];
    
    // in a real app, you'd save the refresh_token & auth host to the keychain, and on
    // relaunch, try and intialize your client from that first, so that you can skip
    // the login step.
    //
    // [controller setClient:client];
    self.feedItems = [NSArray arrayWithObjects:@"one", @"two", nil];
    NSLog(@"got auth callback");
}

-(void)dealloc {
    [_feedItems release];
    [super dealloc];
}

@end
