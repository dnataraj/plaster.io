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
#import "TSClientStartPanelController.h"
#import "TSPlasterController.h"
#import "Carbon/Carbon.h"

@implementation TSAppDelegate {
    NSStatusItem *_plasterStatusItem;
    TSRedisController *_redisController;
    TSPlasterController *_plaster;
    TSClientPreferenceController *_preferenceController;
    NSMenu *_peersMenu;
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AD: Delegate initializing...");
        _redisController = [[TSRedisController alloc] init];
        _plaster = [[TSPlasterController alloc] initWithPasteboard:[NSPasteboard generalPasteboard] provider:_redisController];
        
        // Initialize the peers menu
        _peersMenu = [[NSMenu alloc] initWithTitle:@"Peers Menu"];
        
        NSLog(@"AD: Registering default preferences...");
        // Register application default preferences
        NSMutableDictionary *defaultPreferences = [NSMutableDictionary dictionary];
        [defaultPreferences setObject:[[NSHost currentHost] localizedName] forKey:@"plaster-device-name"];
        [defaultPreferences setObject:[TSClientIdentifier createUUID] forKey:@"plaster-session-id"];
        [defaultPreferences setObject:[NSNumber numberWithBool:YES] forKey:@"plaster-allow-text"];
        [defaultPreferences setObject:[NSNumber numberWithBool:NO] forKey:@"plaster-allow-images"];
        
        // This let's us know (I hope) whether the client is being installed/started for the first time.
        // This will be flipped when the User dismisses the start configuration panel.
        [defaultPreferences setObject:[NSNumber numberWithBool:NO] forKey:@"plaster-init"];
        [defaultPreferences setObject:[NSNumber numberWithBool:NO] forKey:@"plaster-test-mode"];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];        
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self.joinSessionHUD orderOut:nil];
    NSLog(@"AD: Application Launched.");
}

- (void)awakeFromNib {
    NSLog(@"AD: Waking up from nib...");
    _plasterStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [_plasterStatusItem setTitle:@"P"];
    [_plasterStatusItem setHighlightMode:YES];
    [_plasterStatusItem setMenu:[self plasterMenu]];
    
    [self.plasterMenu setAutoenablesItems:NO];
    
    // The user can either join an existing session (by entering the session key)
    // or start a new session - and the key is copied to the pasteboard
    [self.joinMenuItem setEnabled:YES];

    NSImage *play = [NSImage imageNamed: @"play"];
    [play setScalesWhenResized: YES];
    [play setSize: NSMakeSize(16, 16)];
    [self.startStopPlasterMenuItem setImage:play];
    
    // If a session key exists, allow the user to start plastering with this session
    NSString *existingSessionKey = [[NSUserDefaults standardUserDefaults] stringForKey:PLASTER_SESSION_KEY_PREF];
    if (existingSessionKey) {
        [self.startStopPlasterMenuItem setEnabled:YES];
        [self setSessionKey:existingSessionKey];
        [_plaster setSessionKey:existingSessionKey];
    } else {
        [self.startStopPlasterMenuItem setEnabled:NO];
    }
    
    // Obviously, we've just woken up - no peers to show.
    [self.peersMenuItem setEnabled:NO];
    // Attach the peers submenu to this item (NB : This did not work in -init:, self init not complete!)
    [_peersMenu setDelegate:self];
    [self.peersMenuItem setSubmenu:_peersMenu];
}

- (IBAction)start:(id)sender {
    NSString *alias = [[NSUserDefaults standardUserDefaults] stringForKey:PLASTER_DEVICE_NAME_PREF];
    [_plaster setAlias:alias];
    [_plaster start];
    
    // Update the peers menu
    [self menuNeedsUpdate:_peersMenu];

    // When plaster is running, the user cannot join another session or create a new one
    // without stopping it first.
    [self.joinMenuItem setEnabled:NO];
    
    // Toggle the text/image of the startstop button so that it is in the "stop" mode
    [self.startStopPlasterMenuItem setTitle:@"Stop Plaster"];
    NSImage *stop = [NSImage imageNamed: @"stop"];
    [stop setScalesWhenResized: YES];
    [stop setSize: NSMakeSize(16, 16)];
    [self.startStopPlasterMenuItem setImage:stop];
    [self.startStopPlasterMenuItem setEnabled:YES];
}

- (IBAction)stop:(id)sender {
    [_plaster stop];
    // Remove the peers submenu until the session is resumed
    [self menuNeedsUpdate:_peersMenu];
    [self.peersMenuItem setEnabled:NO];
    
    // Since plaster has essentially stopped, you can either join another session
    // or create a new one. So enable these options again.
    [self.joinMenuItem setEnabled:YES];
    
    // Toggle the text/image of the startstop button so that it is in the "start" mode
    [self.startStopPlasterMenuItem setTitle:@"Start Plaster"];
    NSImage *play = [NSImage imageNamed: @"play"];
    [play setScalesWhenResized: YES];
    [play setSize: NSMakeSize(16, 16)];
    [self.startStopPlasterMenuItem setImage:play];
    [self.startStopPlasterMenuItem setEnabled:YES];
}

- (IBAction)showPreferences:(id)sender {
    if (!_preferenceController) {
        _preferenceController = [[TSClientPreferenceController alloc] init];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [_preferenceController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"AD: Quitting...");
    if ([[self.startStopPlasterMenuItem title] isEqualToString:@"Stop Plaster"]) {
        [self stop:self];
    }
}

- (void)showJoinHUD:(id)sender {
    [self.joinSessionHUD makeKeyAndOrderFront:nil];
}

- (void)cancelJoinSession:(id)sender {
    [self.joinSessionHUD orderOut:nil];
}

- (void)startStopPlaster:(id)sender {
    // Check if the user is starting or stopping and take action accordingly.
    if ([[self.startStopPlasterMenuItem title] isEqualToString:@"Start Plaster"]) {
        [self start:self];
    } else if ([[self.startStopPlasterMenuItem title] isEqualToString:@"Stop Plaster"]) {
        [self stop:self];
    }
}

- (void)joinSession:(id)sender {
    [self.joinSessionHUD orderOut:nil];
    self.sessionKey = [[self joinSessionKeyTextField] stringValue];
    NSLog(@"AD: Joining plaster session with key [%@]", self.sessionKey);
    [[NSUserDefaults standardUserDefaults] setObject:self.sessionKey forKey:PLASTER_SESSION_KEY_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_plaster setSessionKey:self.sessionKey];
    
    [self start:nil];    
}

- (void)createNewSession:(id)sender {
    [self willChangeValueForKey:@"sessionKey"];
    self.sessionKey = [TSClientIdentifier createUUID];
    [self didChangeValueForKey:@"sessionKey"];
}

#pragma mark Peer menu delegate methods.

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSArray *peers = [_plaster connectedPeers];
    BOOL anyPeers = ([peers count] > 0);
    if ([[menu title] isEqualToString:@"Plaster Menu"]) {
        [self.peersMenuItem setEnabled:anyPeers];
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

- (void)dealloc {
    [_plaster release];
    [_redisController release];
    [_plasterStatusItem release];
    [_preferenceController release];
    [_peersMenuItem setSubmenu:nil];
    [_peersMenu release];
    
    [super dealloc];
}



@end
