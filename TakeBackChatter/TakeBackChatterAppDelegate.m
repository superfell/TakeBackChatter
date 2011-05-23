//
//  TakeBackChatterAppDelegate.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "TakeBackChatterAppDelegate.h"
#import "FeedController.h"
#import "zkSforce.h"
#import "credential.h"
#import <BayesianKit/BayesianKit.h>

@implementation TakeBackChatterAppDelegate

@synthesize window, feedController, loginMenu, logoutMenu;

static NSString *OAUTH_CLIENTID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF0T4Kw7LW_opx3J5Tj4AizUt0an8hoogMWADGIJaqUgLkVomaqyz5RRIHD4L";
static NSString *OAUTH_CALLBACK = @"compocketsoaptakebackchatter:///oauthdone";

-(IBAction)startLogin:(id)sender {
    // build the URL to the oauth page with our client_id & callback URL set.
    NSString *login = [NSString stringWithFormat:@"%@/services/oauth2/authorize?response_type=token&client_id=%@&redirect_uri=%@",
                       [sender representedObject],
                       [OAUTH_CLIENTID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                       [OAUTH_CALLBACK stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:login];
    
    // ask the OS to open browser to the URL
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)registerDefaults {
    NSArray *servers = [NSArray arrayWithObjects:@"https://login.salesforce.com", @"https://test.salesforce.com", nil];
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:servers forKey:@"servers"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

-(void)setupLoginMenu {
    NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:[loginMenu title]] autorelease];
    for (NSString *server in [[NSUserDefaults standardUserDefaults] arrayForKey:@"servers"]) {
        NSMenuItem *i = [[[NSMenuItem alloc] initWithTitle:server action:@selector(startLogin:) keyEquivalent:@""] autorelease];
        [i setRepresentedObject:server];
        [subMenu addItem:i];
    }
    [loginMenu setSubmenu:subMenu];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // tell the event manager what to do when it gets asked to open a URL (the oauth completion callback) 
    // this callback URL is registered to this app in the info.plist file
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(getUrl:withReplyEvent:) 
                                                     forEventClass:kInternetEventClass 
                                                        andEventID:kAEGetURL];

    [self registerDefaults];
    [self setupLoginMenu];
    
    NSArray *creds = [Credential credentialsForServer:@"https://login.salesforce.com"];
    for (Credential *c in creds) {
        if ([[c username] isEqualToString:@"chatter"]) {
            NSString *refreshToken = [c password];
            NSURL *authHost = [NSURL URLWithString:[c server]];
            ZKSforceClient *client = [[ZKSforceClient alloc] init];
            [client loginWithRefreshToken:refreshToken authUrl:authHost oAuthConsumerKey:OAUTH_CLIENTID];
            self.feedController.sforce = client;
            [client release];
        }
    }
}

-(void)logout:(id)sender {
    NSArray *creds = [Credential credentialsForServer:@"https://login.salesforce.com"];
    for (Credential *c in creds) {
        if ([[c username] isEqualToString:@"chatter"]) {
            [c removeFromKeychain];
        }
    }
    self.feedController.sforce = nil;
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
	// Now you can parse the URL and perform whatever action is needed
    
    ZKSforceClient *client = [[[ZKSforceClient alloc] init] autorelease];
    [client loginFromOAuthCallbackUrl:url oAuthConsumerKey:OAUTH_CLIENTID];
    
    // in a real app, you'd save the refresh_token & auth host to the keychain, and on
    // relaunch, try and intialize your client from that first, so that you can skip
    // the login step.

    ZKOAuthInfo *oauth = (ZKOAuthInfo *)[client authenticationInfo];
    NSString *refreshToken = [oauth refreshToken];
    NSURL *authHost = [oauth authHostUrl];
    [Credential createCredentialForServer:[authHost absoluteString] username:[[client currentUserInfo] userName] password:refreshToken];
    
    NSLog(@"got auth callback");
    self.feedController.sforce = client;
}

-(NSString *)classifierFilename {
    NSArray * dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appDir = [[dirs objectAtIndex:0] stringByAppendingPathComponent:@"TakeBackChatter"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *corpusFile = [appDir stringByAppendingPathComponent:@"corpus.bks"];
    return corpusFile;
}

-(BKClassifier *)classifier {
    if (classifier == nil) {
        NSString *corpusFile = [self classifierFilename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:corpusFile])
            classifier = [[BKClassifier alloc] initWithContentsOfFile:corpusFile];
        else
            classifier = [[BKClassifier alloc] init];
    }
    return classifier;
}

-(void)applicationWillTerminate:(NSNotification *)notification {
    if (classifier != nil)
        [classifier writeToFile:[self classifierFilename]];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

-(void)dealloc {
    [feedController release];
    [classifier release];
    [super dealloc];
}

@end
