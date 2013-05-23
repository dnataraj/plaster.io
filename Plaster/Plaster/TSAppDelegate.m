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

static TSClientIdentifier *_clientIdentifier = nil;

void handlePeerCopy(redisAsyncContext *c, void *reply, void *data) {
    if (reply == NULL) {
        return;
    }
    redisReply *r = reply;
    if (r->type == REDIS_REPLY_ARRAY) {
        for (int j = 0; j < r->elements; j++) {
            printf("%u) %s\n", j, r->element[j]->str);
        }
        // Looks like #3 is our packet...
        if (r->elements > 2) {
            char *bytes = r->element[2]->str;
            if (bytes) {
                NSDictionary *payload = [TSPacketSerializer dictionaryFromJSON:bytes];
                TSPasteboardPacket *packet = [[TSPasteboardPacket alloc] initWithTag:@"plaster-packet-string"
                                                                           andString:[payload objectForKey:@"plaster-packet-string"]];
                
                NSLog(@"Obtained packet [%@]", packet);
                NSPasteboard *pb = (__bridge NSPasteboard *)data;
                if (!pb) {
                    NSLog(@"No pasteboard available...");
                    return;
                }
                NSLog(@"Pasting...");
                [pb clearContents];
                BOOL ok = [pb writeObjects:[NSArray arrayWithObject:packet]];
                if (ok) {
                    NSLog(@"Peer copy successfully written to local pasteboard.");
                }
            }
        }
    }
}

void handlePeerPaste(redisAsyncContext *c, void *reply, void *data) {
    if (reply == NULL) {
        return;
    }
    NSLog(@"Pasting to peers...");
}

@implementation TSAppDelegate {
    NSStatusItem *_plasterStatusItem;
    TSRedisController *_redisController;
    NSMutableArray *_subscriptionList;
    TSPlasterController *_plaster;
    TSClientPreferenceController *_preferenceController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _redisController = [[TSRedisController alloc] init];
    _plaster = [[TSPlasterController alloc] initWithPasteboard:[NSPasteboard generalPasteboard] andProvider:_redisController];

    _clientIdentifier = [[TSClientIdentifier alloc] init];
    NSLog(@"Initializing plaster session with id [%@] and spider-key [%@]", [TSClientIdentifier clientID], [_clientIdentifier spiderKey]);
    
    // Register application default preferences
    NSMutableDictionary *defaultPreferences = [NSMutableDictionary dictionary];
    [defaultPreferences setObject:[_clientIdentifier spiderKey] forKey:@"plaster-spider-key"];
    [defaultPreferences setObject:[NSNumber numberWithBool:YES] forKey:@"plaster-allow-text"];
    [defaultPreferences setObject:[NSNumber numberWithBool:NO] forKey:@"plaster-allow-images"];
    
    // This let's us know (I hope) whether the client is being installed/started for the first time.
    // This will be flipped when the User dismisses the start configuration panel.
    [defaultPreferences setObject:[NSNumber numberWithBool:NO] forKey:@"plaster-init"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
    NSLog(@"Ready to roll...");
}

- (void)awakeFromNib {
    _plasterStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_plasterStatusItem setTitle:@"P"];
    [_plasterStatusItem setHighlightMode:YES];
    [_plasterStatusItem setMenu:[self plasterMenu]];
    
    [self.plasterMenu setAutoenablesItems:NO];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
}

- (IBAction)start:(id)sender {
    BOOL initialized = [[NSUserDefaults standardUserDefaults] boolForKey:@"plaster-init"];
    if (!initialized) {
        TSClientStartPanelController *startPanelController = [[TSClientStartPanelController alloc] init];
        NSLog(@"Starting modal configuration panel for Plaster...");
        [NSApp runModalForWindow:[startPanelController window]];
    }
    NSLog(@"Setting up subscriptions...");
    _subscriptionList = [[NSMutableArray alloc] initWithObjects:@"device1", @"device2", nil];
    [_redisController subscribeToChannels:_subscriptionList withCallback:NULL andContext:(void *)[NSPasteboard generalPasteboard]];
    NSLog(@"Starting pasteboard monitoring every 15ms");
    [_plaster scheduleMonitorWithID:[TSClientIdentifier clientID] andTimeInterval:0.015];
    [self.startMenuItem setEnabled:NO];
    [self.stopMenuItem setEnabled:YES];
}

- (IBAction)stop:(id)sender {
    NSLog(@"Stopping timer and cleaning up...");
    [_plaster invalidateMonitorWithID:[TSClientIdentifier clientID]];
    [_redisController unsubscribe];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
}

- (IBAction)showPreferences:(id)sender {
    if (!_preferenceController) {
        _preferenceController = [[TSClientPreferenceController alloc] init];
    }
    
    [_preferenceController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"Quitting...");
    if ([self.stopMenuItem isEnabled]) {
        [_plaster invalidateMonitorWithID:[TSClientIdentifier clientID]];
        [_redisController unsubscribe];
    }
    [_redisController terminate];
}

@end
