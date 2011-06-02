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
#import "ZKLoginController.h"
#import <BayesianKit/BayesianKit.h>

@implementation TakeBackChatterAppDelegate

@synthesize loginMenu, logoutMenu;

static NSString *OAUTH_CLIENTID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF0T4Kw7LW_opx3J5Tj4AizUt0an8hoogMWADGIJaqUgLkVomaqyz5RRIHD4L";
static NSString *OAUTH_CALLBACK = @"compocketsoaptakebackchatter:///oauthdone";

static NSString *PREFS_SERVER_KEY = @"oauth_servers";
static NSString *PREFS_SHOW_API_LOGIN = @"api_login";

static NSString *KEYCHAIN_CRED_COMMENT = @"oauth token";

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

-(IBAction)startApiLogin:(id)sender {
    NSLog(@"Todo API Login");
    ZKLoginController *c = [[ZKLoginController alloc] init];
    [c showLoginWindow:self target:self selector:@selector(showFeedForClient:)];
}

-(void)registerDefaults {
    NSArray *servers = [NSArray arrayWithObjects:@"https://login.salesforce.com", @"https://test.salesforce.com", nil];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithCapacity:10];
    [defaults setObject:servers forKey:PREFS_SERVER_KEY];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:PREFS_SHOW_API_LOGIN];
    [ZKLoginController addToDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

-(void)setupLoginMenu {
    NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:[loginMenu title]] autorelease];
    for (NSString *server in [[NSUserDefaults standardUserDefaults] arrayForKey:PREFS_SERVER_KEY]) {
        NSMenuItem *i = [[[NSMenuItem alloc] initWithTitle:server action:@selector(startLogin:) keyEquivalent:@""] autorelease];
        [i setRepresentedObject:server];
        [subMenu addItem:i];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_API_LOGIN]) {
        [subMenu addItem:[NSMenuItem separatorItem]];
        NSMenuItem *i = [[[NSMenuItem alloc] initWithTitle:@"API Login" action:@selector(startApiLogin:) keyEquivalent:@""] autorelease];
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
    FeedDataSource *src = [[[FeedDataSource alloc] initWithSforceClient:client] autorelease];
    FeedViewController *ctrl = [[FeedViewController alloc] initWithDataSource:src];
    [src loadNewerRows:self];
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
            if (![[c comment] isEqualToString:KEYCHAIN_CRED_COMMENT]) continue;

            NSString *refreshToken = [c password];
            if ([refreshToken length] < 20) continue;
            
            NSURL *authHost = [NSURL URLWithString:[c server]];
            ZKSforceClient *client = [[[ZKSforceClient alloc] init] autorelease];
            @try {
                [client loginWithRefreshToken:refreshToken authUrl:authHost oAuthConsumerKey:OAUTH_CLIENTID];
                [self addLogoutMenuItem:c];
                [self showFeedForClient:client];
            } @catch (NSException *ex) {
                NSLog(@"error with refresh token %@", [ex reason]);
            }
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

    Credential *cred = [Credential createCredentialForServer:[authHost absoluteString] username:[[client currentUserInfo] userName] password:refreshToken];
    [cred setComment:KEYCHAIN_CRED_COMMENT];
    
    [self addLogoutMenuItem:cred];
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
