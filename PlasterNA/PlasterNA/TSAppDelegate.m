//
//  TSAppDelegate.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSAppDelegate.h"
#import "TSPlasterGlobals.h"
#import "TSStack.h"
#import "TSPasteboardPacket.h"
#import "TSRedisController.h"
#import "TSEventDispatcher.h"
#import "TSBase64/NSString+TSBase64.h"
#import "TSPacketSerializer.h"
#import "TSClientIdentifier.h"
#import "TSClientPreferenceController.h"
#import "TSProfileConfigurationViewController.h"
#import "TSPlasterController.h"
#import "Carbon/Carbon.h"

@implementation TSAppDelegate {
    NSStatusItem *_plasterStatusItem;
    TSRedisController *_redisController;
    TSPlasterController *_plaster;
    TSClientPreferenceController *_preferenceController;
    NSMenu *_peersMenu, *_profilesMenu;
    
    NSUserDefaults *_userDefaults;
    TSProfileConfigurationViewController *_joinProfileConfigurationViewController, *_freshProfileConfigurationViewController;
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AD: Delegate initializing...");
        _userDefaults = [[NSUserDefaults standardUserDefaults] retain];
        _redisController = [[TSRedisController alloc] init];
        _plaster = [[TSPlasterController alloc] initWithPasteboard:[NSPasteboard generalPasteboard] provider:_redisController];
        
        // Initialize the peers menu
        _peersMenu = [[NSMenu alloc] initWithTitle:@"Peers Menu"];
        _profilesMenu = [[NSMenu alloc] initWithTitle:@"Profiles Menu"];
        
        NSLog(@"AD: Registering default preferences...");
        // Register application default preferences
        NSMutableDictionary *defaultPreferences = [NSMutableDictionary dictionary];
        [defaultPreferences setObject:[[NSHost currentHost] localizedName] forKey:TSPlasterDeviceName];
        
        // A test mode flag to allow file logging
        [defaultPreferences setObject:@NO forKey:@"plaster-test-mode"];
        
        [_userDefaults registerDefaults:defaultPreferences];
        
        _joinProfileConfigurationViewController = [[TSProfileConfigurationViewController alloc] init];
        _freshProfileConfigurationViewController = [[TSProfileConfigurationViewController alloc] init];
    }
    
    return self;
}

- (void)awakeFromNib {
    NSLog(@"AD: Waking up from nib...");
    _plasterStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [_plasterStatusItem setTitle:@"P"];
    /*
    NSImage *plaster = [NSImage imageNamed: @"plaster"];
    [plaster setScalesWhenResized: YES];
    [plaster setSize: NSMakeSize(19, 19)];
    [_plasterStatusItem setImage:plaster];
    */
    [_plasterStatusItem setHighlightMode:YES];
    [_plasterStatusItem setMenu:[self plasterMenu]];
    [self.plasterMenu setAutoenablesItems:NO];
    
    NSImage *stop = [NSImage imageNamed: @"stop"];
    [stop setScalesWhenResized: YES];
    [stop setSize: NSMakeSize(16, 16)];
    [_stopMenuItem setImage:stop];
    
    // Set up the profiles menu
    [_profilesMenu setDelegate:self];
    [self.startWithProfileMenuItem setSubmenu:_profilesMenu];
    
    // Attach the peers submenu to this item (NB : This did not work in -init:, self init not complete!)
    [_peersMenu setDelegate:self];
    [self.peersMenuItem setSubmenu:_peersMenu];
    
    // Set up the HUD's for join and new sessions
    [_joinProfileConfigurationView addSubview:[_joinProfileConfigurationViewController view]];
    [_freshProfileConfigurationView addSubview:[_freshProfileConfigurationViewController view]];
}

- (IBAction)start:(id)sender {
    NSString *alias = [_userDefaults stringForKey:TSPlasterDeviceName];
    [_plaster setAlias:alias];
    [_plaster start];
    
    // When plaster is running, the user cannot join another session or create a new one
    // without stopping it first.
    [self.joinMenuItem setEnabled:NO];
    [self.freshSessionMenuItem setEnabled:NO];
    
    // The user can create a profile for the running session, if one does not already
    [self.saveAsMenuItem setEnabled:YES];
    NSDictionary *profiles = [_userDefaults dictionaryForKey:TSPlasterProfiles];
    if ([profiles objectForKey:self.sessionKey]) {
        [self.saveAsMenuItem setEnabled:NO];
    }
    
    // Toggle the text/image of the startstop button so that it is in the "stop" mode
    [_stopMenuItem setToolTip:_currentProfileName];
    [_startWithProfileMenuItem setHidden:YES];
    [_stopMenuItem setHidden:NO];
}

- (void)startPlasterWithProfile:(id)sender {
    NSLog(@"Starting plaster session for : %@", [sender title]);
    [self setCurrentProfileName:[sender title]];
    [self setSessionKey:[sender toolTip]];
    [sender setState:NSOnState];
    
    // Get this profiles configuration, and set it on the plaster controller
    NSDictionary *profiles = [_userDefaults dictionaryForKey:TSPlasterProfiles];
    [_plaster setSessionProfile:[profiles objectForKey:_sessionKey]];
    // Set the Plaster Controller's session key and start it.
    [_plaster setSessionKey:_sessionKey];
    [self start:nil];
}

- (IBAction)stop:(id)sender {
    [_plaster stop];
    // Remove the peers submenu until the session is resumed
    //[self menuNeedsUpdate:_peersMenu];
    [self.peersMenuItem setEnabled:NO];
    
    // Since plaster has essentially stopped, you can either join another session
    // or create a new one. So enable these options again.
    [self.joinMenuItem setEnabled:YES];
    [self.freshSessionMenuItem setEnabled:YES];
    
    [_startWithProfileMenuItem setHidden:NO];
    [_startWithProfileMenuItem setEnabled:YES];
    [_stopMenuItem setHidden:YES];
}

#pragma mark Joining a Session

- (void)showJoinHUD:(id)sender {
    NSMutableDictionary *newProfile = [[self newProfileWithName:@"*untitled"] autorelease];
    [_joinProfileConfigurationViewController configureWithProfile:newProfile];
    [self.joinSessionKeyTextField setStringValue:@""];
    [self.joinSessionHUD makeKeyAndOrderFront:nil];
}

- (void)cancelJoinSession:(id)sender {
    [self.joinSessionHUD orderOut:nil];
}

- (void)joinSession:(id)sender {
    [self.joinSessionHUD orderOut:nil];
    self.sessionKey = [self.joinSessionKeyTextField stringValue];
    NSLog(@"AD: Joining plaster session with key [%@]", self.sessionKey);
    [_plaster setSessionKey:self.sessionKey];
    [_plaster setSessionProfile:[_joinProfileConfigurationViewController getProfileConfiguration]];
    self.currentProfileName = @"*untitled";
        
    [self start:nil];
}

#pragma mark Starting a new Session

- (void)freshSession:(id)sender {
    [self willChangeValueForKey:@"sessionKey"];
    self.sessionKey = [TSClientIdentifier createUUID];
    [self didChangeValueForKey:@"sessionKey"];
    
    // Write the new session key to the pasteboard.
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    BOOL ok = [pb writeObjects:@[_sessionKey]];
    NSAssert(ok == YES, @"AD: Error writing generated session key to pasteboard : %@", self.sessionKey);

    self.currentProfileName = @"*untitled";
    NSMutableDictionary *newProfile = [[self newProfileWithName:@"*untitled"] autorelease];
    [_freshProfileConfigurationViewController configureWithProfile:newProfile];

    [self.freshSessionKeyTextField setStringValue:_sessionKey];
    [self.freshSessionHUD makeKeyAndOrderFront:nil];
}

- (void)startFreshSession:(id)sender {
    [self.freshSessionHUD orderOut:nil];
    // Set this new session key on the Plaster Controller.
    [_plaster setSessionKey:self.sessionKey];
    // Create a new "untitled" default profile
    [_plaster setSessionProfile:[_freshProfileConfigurationViewController getProfileConfiguration]];
    [self start:nil];
}

#pragma mark Saving a profile

- (void)showSaveProfileHUD:(id)sender {
    [self.saveProfileHUD makeKeyAndOrderFront:nil];
}

- (void)cancelSaveProfile:(id)sender {
    [self.saveProfileHUD orderOut:nil];
}

- (void)saveProfile:(id)sender {
    // Reload the profile container since the user might have changed this using preferences.
    NSMutableDictionary *mutableProfiles = [[_userDefaults dictionaryForKey:TSPlasterProfiles] mutableCopy];
    NSMutableDictionary *profiles = [[NSMutableDictionary alloc] initWithDictionary:mutableProfiles];
    [mutableProfiles release];
    
    NSString *profileName = [self.profileNameTextField stringValue];
    NSLog(@"AD: Saving profile with name : %@", profileName);
    NSMutableDictionary *profileConfiguration = [[NSMutableDictionary alloc] initWithDictionary:[_plaster sessionProfile]];
    [profileConfiguration setObject:profileName forKey:TSPlasterProfileName];
    
    NSLog(@"Adding profile : %@ to profiles with key : %@", profileName, self.sessionKey);
    [profiles setObject:profileConfiguration forKey:self.sessionKey];
    // Replace the "dummy" profile that the plaster controller started with.
    [_plaster setSessionProfile:profileConfiguration];
    
    // Once this session has been saved, it cannot be saved again (not even with another name - for now.)
    [self.saveAsMenuItem setEnabled:NO];
    [self.saveProfileHUD orderOut:nil];
    
    // Save the user preferences.
    [_userDefaults setObject:profiles forKey:TSPlasterProfiles];
    
    // Set the current profile and necessary tooltips
    [self setCurrentProfileName:profileName];
    [_startWithProfileMenuItem setToolTip:profileName];
    [_stopMenuItem setToolTip:profileName];
    
    [profiles release];
}

#pragma Other utility methods

- (NSMutableDictionary *)newProfileWithName:(NSString *)profileName {
    NSMutableDictionary *profileConfiguration = [[NSMutableDictionary alloc] init];
    [profileConfiguration setObject:profileName forKey:TSPlasterProfileName];
    
    // By default the user can recieve text and images, but not files.
    [profileConfiguration setObject:@YES forKey:TSPlasterAllowText];
    [profileConfiguration setObject:@YES forKey:TSPlasterAllowImages];
    [profileConfiguration setObject:@YES forKey:TSPlasterAllowFiles];
    
    // By default the user only sends out images and files, but not clipboard text.
    [profileConfiguration setObject:@NO forKey:TSPlasterOutAllowText];
    [profileConfiguration setObject:@YES forKey:TSPlasterOutAllowImages];
    [profileConfiguration setObject:@YES forKey:TSPlasterOutAllowFiles];
    
    [profileConfiguration setObject:TSPlasterModePasteboard forKey:TSPlasterMode];
    [profileConfiguration setObject:NSHomeDirectory() forKey:TSPlasterFolderPath];
    [profileConfiguration setObject:@YES forKey:TSPlasterNotifyJoins];
    [profileConfiguration setObject:@YES forKey:TSPlasterNotifyDepartures];
    [profileConfiguration setObject:@YES forKey:TSPlasterNotifyPlasters];
    
    return profileConfiguration;
}

- (void)buildProfilesMenu {
    if ([_startWithProfileMenuItem isHidden]) {
        return;
    }
    
    NSDictionary *profiles = [_userDefaults dictionaryForKey:TSPlasterProfiles];
    
    // If there are no profiles, disable the "Start With Profile" menu item.
    if (![profiles count]) {
        [self.startWithProfileMenuItem setEnabled:NO];
        return;
    }
    
    // Prep the parent menu
    [_profilesMenu removeAllItems];
    
    // Check for profiles and build the submenu
    for (NSString *profileKey in [profiles keyEnumerator]) {
        NSLog(@"AD: Found saved profile : %@", profileKey);
        NSDictionary *profileConfiguration = [profiles objectForKey:profileKey];
        NSString *profileName = [profileConfiguration objectForKey:TSPlasterProfileName];
        NSMenuItem *profileMenuItem = [[[NSMenuItem alloc] initWithTitle:profileName action:@selector(startPlasterWithProfile:) keyEquivalent:@""] autorelease];
        [profileMenuItem setTarget:self];
        [profileMenuItem setEnabled:YES];
        [profileMenuItem setState:NSOffState];
        if ([profileName isEqualToString:_currentProfileName]) {
            [profileMenuItem setState:NSOnState];
        }
        [profileMenuItem setToolTip:profileKey];
        [_profilesMenu addItem:profileMenuItem];
    }
}

#pragma mark Show Preferences Dialog

- (IBAction)showPreferences:(id)sender {
    if (!_preferenceController) {
        _preferenceController = [[TSClientPreferenceController alloc] init];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [_preferenceController showWindow:self];
}

#pragma mark Text control delegate methods

- (void)controlTextDidChange:(NSNotification *)obj {
    if ([[self.joinSessionKeyTextField stringValue] length] == 36) {
        [self.okButton setEnabled:YES];
        return;
    }
    if ([[[self profileNameTextField] stringValue] length] > 0) {
        [self.saveProfileButton setEnabled:YES];
        return;
    }
    
    [self.saveProfileButton setEnabled:NO];
    [self.okButton setEnabled:NO];
}

#pragma mark Peer menu delegate methods.

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSArray *peers = [_plaster connectedPeers];
    BOOL anyPeers = ([peers count] > 0);
    if ([[menu title] isEqualToString:@"Plaster Menu"]) {
        [self.peersMenuItem setEnabled:anyPeers];
        [self buildProfilesMenu];
        return;
    }
    
    [_peersMenu removeAllItems];
    if (anyPeers) {
        for (NSString *peer in peers) {
            //NSLog(@"Adding peer : %@", peer);
            NSMenuItem *peerMenuItem = [[[NSMenuItem alloc] initWithTitle:peer action:@selector(_no_op:) keyEquivalent:@""] autorelease];
            [peerMenuItem setTarget:self];
            [peerMenuItem setEnabled:YES];
            [_peersMenu addItem:peerMenuItem];
        }
    }
    return;
}

#pragma mark Application Delegate methods

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"AD: Quitting...");
    if ([[_startWithProfileMenuItem title] isEqualToString:@"Stop Plaster"]) {
        [self stop:self];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self.joinSessionHUD orderOut:nil];
    NSLog(@"AD: Application Launched.");
}

#pragma mark Deallocations

- (void)dealloc {
    [_plaster release];
    [_redisController release];
    [_plasterStatusItem release];
    [_preferenceController release];
    [_peersMenuItem setSubmenu:nil];
    [_peersMenu release];
    [_joinProfileConfigurationViewController release];
    [_freshProfileConfigurationViewController release];
    
    [super dealloc];
}

@end
