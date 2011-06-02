// Copyright (c) 2006-2009 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import "ZKLoginController.h"
#import "credential.h"
#import "zkSforceClient.h"
#import "zkSoapException.h"
#import "zkLoginResult.h"

@implementation ZKLoginController

static NSString * login_lastUsernameKey = @"login_lastUserName";
static NSString *prod = @"https://login.salesforce.com";
static NSString *test = @"https://test.salesforce.com";

+(NSSet *)keyPathsForValuesAffectingCredentials {
    return [NSSet setWithObject:@"server"];
}

+(NSSet *)keyPathsForValuesAffectingCanDeleteServer {
    return [NSSet setWithObject:@"server"];
}

+(NSSet *)keyPathsForValuesAffectingPassword {
    return [NSSet setWithObject:@"username"];
}

+(void)addToDefaults:(NSMutableDictionary *)defaults {
    [defaults setObject:[NSArray arrayWithObjects:prod, test, nil] forKey:@"servers"];
    [defaults setObject:prod forKey:@"server"];
}

- (id)init {
	self = [super init];
	server = [[[NSUserDefaults standardUserDefaults] objectForKey:@"server"] copy];
	[self setUsername:[[NSUserDefaults standardUserDefaults] objectForKey:login_lastUsernameKey]];
	return self;
}

- (void)setImage:(NSString *)name onButton:(NSButton *)b {
	NSString *imgFile = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:imgFile] autorelease];
	[b setImage:img];
}

- (void)awakeFromNib {
	[self setImage:@"plus-8" onButton:addButton];
	[self setImage:@"minus-8" onButton:delButton];
	[loginProgress setUsesThreadedAnimation:YES];
	[loginProgress setHidden:YES];
	[loginProgress setDoubleValue:22.0];
}

- (void)dealloc {
	[username release];
	[password release];
	[server release];
	[clientId release];
	[credentials release];
	[selectedCredential release];
	[sforce release];
	[newUrl release];
	[super dealloc];
}

- (void)loadNib {
	[NSBundle loadNibNamed:@"Login" owner:self];	
}

- (void)setClientIdFromInfoPlist {
	NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
	NSString *cid = [NSString stringWithFormat:@"%@/%@", [plist objectForKey:@"CFBundleName"], [plist objectForKey:@"CFBundleVersion"]];
	[self setClientId:cid];
}

- (void)endModalWindow:(id)sforce {
	[NSApp stopModal];
}

- (ZKSforceClient *)showModalLoginWindow:(id)sender {
	[self loadNib];
	target = self;
	selector = @selector(endModalWindow:);
	modalWindow = nil;
	[NSApp runModalForWindow:window];
	[window close];
	return [sforce loggedIn] ? sforce : nil;
}

- (void)showLoginWindow:(id)sender target:(id)t selector:(SEL)s {
	[self loadNib];
	target = t;
	selector = s;
	modalWindow = nil;
	[window makeKeyAndOrderFront:sender];
}

- (void)showLoginSheet:(NSWindow *)modalForWindow target:(id)t selector:(SEL)s {
	[self loadNib];
	target = t;
	selector = s;
	modalWindow = modalForWindow;
	[NSApp beginSheet:window modalForWindow:modalForWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)restoreLoginWindow:(NSWindow *)w returnCode:(int)rc contextInfo:(id)ctx {
	if (modalWindow != nil) {
		[w orderOut:self];
		[NSApp beginSheet:window modalForWindow:modalWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
}

- (BOOL)canDeleteServer {
	return ([server caseInsensitiveCompare:prod] != NSOrderedSame) && ([server caseInsensitiveCompare:test] != NSOrderedSame);
}

// this will show a new window, handling the fact that the original login window may of been a stand alone window, or already be a sheet.
- (void)showNewWindow:(NSWindow *)newWindowToShow {
	if (modalWindow != nil) {
		[NSApp endSheet:window];
		[window orderOut:self];
	}
	[NSApp beginSheet:newWindowToShow modalForWindow:modalWindow == nil ? window : modalWindow modalDelegate:self didEndSelector:@selector(restoreLoginWindow:returnCode:contextInfo:) contextInfo:nil];	
}

- (IBAction)showAddNewServer:(id)sender {
	[self setNewUrl:@"https://"];
	[self showNewWindow:newUrlWindow];
}

- (IBAction)closeAddNewServer:(id)sender {
	[NSApp endSheet:newUrlWindow];	
	[newUrlWindow orderOut:sender];
}

- (IBAction)deleteServer:(id)sender {
	if (![self canDeleteServer]) return;
	NSArray *servers = [[NSUserDefaults standardUserDefaults] objectForKey:@"servers"];
	NSMutableArray *newServers = [NSMutableArray arrayWithCapacity:[servers count]];
    for (NSString *s in servers) {
		if ([s caseInsensitiveCompare:server] == NSOrderedSame) continue;
		[newServers addObject:s];
	}
	[[NSUserDefaults standardUserDefaults] setObject:newServers forKey:@"servers"];
	[self setServer:prod];
}

- (IBAction)addNewServer:(id)sender {
	NSString *new = [self newUrl];
	if (![new isEqualToString:@"https://"]) {
		NSArray *servers = [[NSUserDefaults standardUserDefaults] objectForKey:@"servers"];
		if (![servers containsObject:new]) {
			NSMutableArray *newServers = [NSMutableArray array];
			[newServers addObjectsFromArray:servers];
			[newServers addObject:new];
			[[NSUserDefaults standardUserDefaults] setObject:newServers forKey:@"servers"];
		}
		[self setServer:new];
		[self closeAddNewServer:sender];
	}
	// Note, Analyze might complain about a leak here, but its just confused because of the newUrl property starting with new. TODO rename it.
}

- (IBAction)cancelLogin:(id)sender {
	if (target == self) {
		[NSApp stopModal];
	} else if (modalWindow != nil) {
		[NSApp endSheet:window];
		[window orderOut:sender];
	} else {
		[window close];
	}
}

- (Credential *)selectedCredential {
	return selectedCredential;
}

- (void)setSelectedCredential:(Credential *)aValue {
	Credential *oldSelectedCredential = selectedCredential;
	selectedCredential = [aValue retain];
	[oldSelectedCredential release];
}

- (void)showAlertSheetWithMessageText:(NSString *)message 
			defaultButton:(NSString *)defaultButton 
			altButton:(NSString *)altButton 
			otherButton:(NSString *)otherButton 
			additionalText:(NSString *)additionalText 
			didEndSelector:(SEL)didEndSelector
			contextInfo:(id)context {
	NSAlert * a = [NSAlert alertWithMessageText:message defaultButton:defaultButton alternateButton:altButton otherButton:otherButton informativeTextWithFormat:additionalText];
	NSWindow *wndForAlertSheet = modalWindow == nil ? window : modalWindow;
	if (modalWindow != nil) {
		[NSApp endSheet:window];
		[window orderOut:self];
	}
	[a beginSheetModalForWindow:(NSWindow *)wndForAlertSheet modalDelegate:self didEndSelector:didEndSelector contextInfo:context];
}

- (void)updateKeychain:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	NSLog(@"updateKeychain rc=%d", returnCode);
	if (returnCode == NSAlertDefaultReturn)
		[[self selectedCredential] update:username password:password];
	[[alert window] orderOut:self];
	[self cancelLogin:self];
	[target performSelector:selector withObject:sforce];	
}

- (void)createKeychain:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	NSLog(@"createKeychain rc=%d", returnCode);
	if (returnCode == NSAlertDefaultReturn) 
		[Credential createCredentialForServer:server username:username password:password];
	[[alert window] orderOut:self];
	[self cancelLogin:self];
	[target performSelector:selector withObject:sforce];	
}

- (void)promptAndAddToKeychain {
	[self showAlertSheetWithMessageText:@"Crete Keychain entry with new username & password?" 
				defaultButton:@"Create Keychain Entry" 
				altButton:@"No thanks" 
				otherButton:nil 
				additionalText:@"" 
				didEndSelector:@selector(createKeychain:returnCode:contextInfo:) 
				contextInfo:nil];
}

- (void)promptAndUpdateKeychain {
	[self showAlertSheetWithMessageText:@"Update Keychain entry with new password?" 
				defaultButton:@"Update Keychain" 
				altButton:@"No thanks" 
				otherButton:nil 
				additionalText:@"" 
				didEndSelector:@selector(updateKeychain:returnCode:contextInfo:) 
				contextInfo:nil];
}

- (ZKSforceClient *)performLogin:(ZKSoapException **)error loginResult:(ZKLoginResult **)loginResult {
	[sforce release];
	sforce = [[ZKSforceClient alloc] init];
	[sforce setLoginProtocolAndHost:server];	
	*loginResult = nil;
	if ([clientId length] > 0)
		[sforce setClientId:clientId];
	@try {
		*loginResult = [sforce login:username password:password];
		[[NSUserDefaults standardUserDefaults] setObject:server forKey:@"server"];
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:login_lastUsernameKey];
	}
	@catch (ZKSoapException *ex) {
		if (error != nil) *error = ex;
		return nil;
	}
	return sforce;
}

-(BOOL)hasLoginHelp {
	return [[NSApp delegate] respondsToSelector:@selector(showLoginHelp:)];
}

-(IBAction)showLoginHelp:(id)sender {
	if ([self hasLoginHelp])
		[[NSApp delegate] performSelector:@selector(showLoginHelp:) withObject:self];
}

-(void)loginErrorClosing:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		[self showLoginHelp:self];
	}
}

-(void)showException:(ZKSoapException *)ex {
	NSString *alt = [self hasLoginHelp] ? @"Help" : nil;
	[self showAlertSheetWithMessageText:[ex reason]
		defaultButton:@"Close"
		altButton:alt
		otherButton:nil
		additionalText:@""
		didEndSelector:@selector(loginErrorClosing:returnCode:contextInfo:)
		contextInfo:nil];	
}


- (void)promptPasswordExpired {
	[self showNewWindow:passwordExpiredWindow];
}

- (IBAction)cancelChangePassword:(id)sender {
	[self setStatusText:@""];
	[NSApp endSheet:passwordExpiredWindow];	
	[passwordExpiredWindow orderOut:sender];
}

- (IBAction)changePassword:(id)sender {
	@try {
		[sforce setPassword:[self password] forUserId:[[sforce currentUserInfo] userId]];
		[self cancelChangePassword:sender];
	} 
	@catch (ZKSoapException *ex) {
		[self setStatusText:[ex reason]];
	}
}

- (IBAction)login:(id)sender {
	[self setStatusText:nil];
	[loginProgress setHidden:NO];
	[loginProgress display];
	@try {
		ZKSoapException *ex = nil;
		ZKLoginResult *lr = nil;
		[self performLogin:&ex loginResult:&lr];
		if (ex != nil) {
			[self setStatusText:[ex reason]];
			[self showException:ex];
			return;
		} 
		if ([lr passwordExpired]) {
			[self promptPasswordExpired];
			return;
		}
		if (selectedCredential == nil || (![[[selectedCredential username] lowercaseString] isEqualToString:[username lowercaseString]])) {
			[self promptAndAddToKeychain];
			return;
		}
		else if (![[selectedCredential password] isEqualToString:password]) {
			[self promptAndUpdateKeychain];
			return;
		}
		[self cancelLogin:sender];
		[target performSelector:selector withObject:sforce];
	}
	@finally {		
		[loginProgress setHidden:YES];
		[loginProgress display];
	}
}

- (NSArray *)credentials {
	if (credentials == nil) {
		// NSComboBox doesn't really bind to an object, its value is always the display string
		// regardless of how many you have with the same name, it doesn't bind the value to 
		// the underlying object (lame), so we filter out all the duplicate usernames
		NSArray *allCredentials = [Credential credentialsForServer:server];
		NSMutableArray * filtered = [NSMutableArray arrayWithCapacity:[allCredentials count]];
		NSMutableSet *usernames = [NSMutableSet set];
        for (Credential *c in allCredentials) {
			if ([usernames containsObject:[[c username] lowercaseString]]) continue;
			[usernames addObject:[[c username] lowercaseString]];
			[filtered addObject:c];
		}
		credentials = [filtered retain];
	}
	return credentials;
}

- (NSString *)server {
	return server;
}

- (void)setPasswordFromKeychain {
	// see if there's a matching credential and default the password if so
    for (Credential *c in [self credentials]) {
		if ([[c username] caseInsensitiveCompare:username] == NSOrderedSame) {
			[self setPassword:[c password]];
			[self setSelectedCredential:c];
			return;
		}
	}
	[self setSelectedCredential:nil];	
}

- (void)setServer:(NSString *)aServer {
	if ([server isEqualToString:aServer]) return;
	[server release];
	server = [aServer copy];
	[credentials release];
	credentials = nil;
	[self setSelectedCredential:nil];
	// we've changed server, so we need to recalc the password
	[self setPasswordFromKeychain];
}

- (NSString *)password {
	return password;
}

- (void)setPassword:(NSString *)aPassword {
	aPassword = [aPassword copy];
	[password release];
	password = aPassword;
}

- (NSString *)username {
	return username;
}

- (void)setUsername:(NSString *)aUsername {
	aUsername = [aUsername copy];
	[username release];
	username = aUsername;
	[self setPasswordFromKeychain];
}

- (NSString *)clientId {
	return clientId;
}

- (void)setClientId:(NSString *)aClientId {
	aClientId = [aClientId copy];
	[clientId release];
	clientId = aClientId;
}

- (NSString *)newUrl {
	return newUrl;
}

- (void)setNewUrl:(NSString *)aNewUrl {
	aNewUrl = [aNewUrl copy];
	[newUrl release];
	newUrl = aNewUrl;
}

- (NSString *)statusText {
	return statusText;
}

- (void)setStatusText:(NSString *)aStatusText {
	aStatusText = [aStatusText copy];
	[statusText release];
	statusText = aStatusText;
}

@end
