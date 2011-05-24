//
//  TakeBackChatterAppDelegate.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/18/11.
//

#import "TakeBackChatterAppDelegate.h"
#import "FeedViewController.h"
#import "FeedDataSource.h"
#import "zkSforce.h"
#import "credential.h"
#import <BayesianKit/BayesianKit.h>

@implementation TakeBackChatterAppDelegate

@synthesize loginMenu, logoutMenu;

static NSString *OAUTH_CLIENTID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF0T4Kw7LW_opx3J5Tj4AizUt0an8hoogMWADGIJaqUgLkVomaqyz5RRIHD4L";
static NSString *OAUTH_CALLBACK = @"compocketsoaptakebackchatter:///oauthdone";

static NSString *PREFS_SERVER_KEY = @"servers";

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
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:servers forKey:PREFS_SERVER_KEY];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

-(void)setupLoginMenu {
    NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:[loginMenu title]] autorelease];
    for (NSString *server in [[NSUserDefaults standardUserDefaults] arrayForKey:PREFS_SERVER_KEY]) {
        NSMenuItem *i = [[[NSMenuItem alloc] initWithTitle:server action:@selector(startLogin:) keyEquivalent:@""] autorelease];
        [i setRepresentedObject:server];
        [subMenu addItem:i];
    }
    [loginMenu setSubmenu:subMenu];
}

-(void)addLogoutMenuItem:(Credential *)c {
    if ([logoutMenu submenu] == nil)
        [logoutMenu setSubmenu:[[[NSMenu alloc] initWithTitle:@"Logout"] autorelease]];
    
    NSMenuItem *i = [[[NSMenuItem alloc] initWithTitle:[c username] action:@selector(logout:) keyEquivalent:@""] autorelease];
    [i setRepresentedObject:c];
    [[logoutMenu submenu] addItem:i];
}

-(void)showFeedForClient:(ZKSforceClient *)client {
    FeedDataSource *src = [[[FeedDataSource alloc] init] autorelease];
    FeedViewController *ctrl = [[FeedViewController alloc] initWithDataSource:src];
    [src setSforce:client];
    [feedControllers addObject:ctrl];
    [ctrl release];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // tell the event manager what to do when it gets asked to open a URL (the oauth completion callback) 
    // this callback URL is registered to this app in the info.plist file
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(getUrl:withReplyEvent:) 
                                                     forEventClass:kInternetEventClass 
                                                        andEventID:kAEGetURL];

    feedControllers = [[NSMutableArray alloc] init];
    [self registerDefaults];
    [self setupLoginMenu];
    
    for (NSString *server in [[NSUserDefaults standardUserDefaults] arrayForKey:PREFS_SERVER_KEY]) {
        for (Credential *c in [Credential credentialsForServer:server]) {
            [self addLogoutMenuItem:c];
            
            NSString *refreshToken = [c password];
            NSURL *authHost = [NSURL URLWithString:[c server]];
            ZKSforceClient *client = [[ZKSforceClient alloc] init];
            [client loginWithRefreshToken:refreshToken authUrl:authHost oAuthConsumerKey:OAUTH_CLIENTID];

            [self showFeedForClient:client];
            
            [client release];
            return; // stop at the first one for now.
        }
    }
}

-(void)logout:(id)sender {
    [[sender representedObject] removeFromKeychain];
    // TODO, close feedController and remove it from feedControllers.
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
    [self showFeedForClient:client];
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
    [feedControllers release];
    [classifier release];
    [super dealloc];
}

@end
