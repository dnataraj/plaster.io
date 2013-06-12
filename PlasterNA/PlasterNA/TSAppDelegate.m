//
//  TSAppDelegate.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSAppDelegate.h"
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

@implementation TSAppDelegate {
    NSStatusItem *_plasterStatusItem;
    TSRedisController *_redisController;
    TSPlasterController *_plaster;
    TSClientPreferenceController *_preferenceController;
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AD: Delegate initializing...");
        _redisController = [[TSRedisController alloc] init];
        _plaster = [[TSPlasterController alloc] initWithPasteboard:[NSPasteboard generalPasteboard] provider:_redisController];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
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
    
    NSLog(@"AD: Application Launched.");
}


- (void)awakeFromNib {
    _plasterStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [_plasterStatusItem setTitle:@"P"];
    [_plasterStatusItem setHighlightMode:YES];
    [_plasterStatusItem setMenu:[self plasterMenu]];
    
    [self.plasterMenu setAutoenablesItems:NO];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
    [self.disconnectMenuItem  setEnabled:NO];
}

- (IBAction)start:(id)sender {
    NSString *alias = [[NSUserDefaults standardUserDefaults] stringForKey:@"plaster-device-name"];
    [_plaster setAlias:alias];
    BOOL initialized = [[NSUserDefaults standardUserDefaults] boolForKey:@"plaster-init"];
    if (!initialized) {
        TSClientStartPanelController *startPanelController = [[TSClientStartPanelController alloc] init];
        NSLog(@"Starting modal configuration panel for Plaster...");
        [NSApp runModalForWindow:[startPanelController window]];
        [startPanelController release];
    }
    [_plaster start];
    NSLog(@"AD: Attaching menu...");
    if ([_plaster connectedPeers]) {
        [self.disconnectMenuItem setSubmenu:[_plaster connectedPeers]];
        [self.disconnectMenuItem setEnabled:YES];        
    }
    
    [self.startMenuItem setEnabled:NO];
    [self.stopMenuItem setEnabled:YES];
}

- (IBAction)stop:(id)sender {
    [_plaster stop];
    [self.disconnectMenuItem setSubmenu:nil];
    [self.disconnectMenuItem setEnabled:NO];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
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
    if ([self.stopMenuItem isEnabled]) {
        [_plaster stop];
    }
}

- (void)dealloc {
    NSLog(@"DELEGATE DEALLOC!!!");
    [_plaster release];
    [_redisController release];
    [_plasterStatusItem release];
    [_preferenceController release];
    
    [super dealloc];
}

@end
