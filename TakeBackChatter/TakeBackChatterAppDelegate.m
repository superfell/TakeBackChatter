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
#import "prefs.h"
#import "Categorizer.h"
#import "Feed.h"

@implementation TakeBackChatterAppDelegate

@synthesize loginMenu, logoutMenu;
@synthesize welcomeWindow;

static NSString *OAUTH_CLIENTID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF0T4Kw7LW_opx3J5Tj4AizUt0an8hoogMWADGIJaqUgLkVomaqyz5RRIHD4L";
static NSString *OAUTH_CALLBACK = @"compocketsoaptakebackchatter:///oauthdone";

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
    if (loginController == nil)
        loginController = [[ZKLoginController alloc] init];
    [loginController showLoginWindow:self target:self selector:@selector(showFeedForClient:)];
}

-(void)registerDefaults {
    NSArray *servers = [NSArray arrayWithObjects:@"https://login.salesforce.com", @"https://test.salesforce.com", nil];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithCapacity:10];
    [defaults setObject:servers forKey:PREFS_SERVER_KEY];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:PREFS_SHOW_API_LOGIN];
    [defaults setObject:[NSNumber numberWithInt:90] forKey:PREFS_JUNK_THRESHOLD];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:PREFS_SHOW_WELCOME];
    [ZKLoginController addToDefaults:defaults];
    [Categorizer addToDefaults:defaults];
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
    [[src feed]loadNewerRows:self];
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_WELCOME]) {
        [self.welcomeWindow makeKeyAndOrderFront:self];
    }
    
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
    
    NSLog(@"oauth callback got url %@", url);
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

-(Categorizer *)categorizer {
    @synchronized(self) {
        if (categorizer == nil) 
            categorizer = [[Categorizer alloc] init];
        return categorizer;
    }
}

-(void)applicationWillTerminate:(NSNotification *)notification {
    [categorizer persist];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

-(void)dealloc {
    [feedControllers release];
    [categorizer release];
    [loginController release];
    [super dealloc];
}

@end
