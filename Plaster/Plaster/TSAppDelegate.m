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
#import "NSString+TSPasteboardString.h"

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
            char *peerPacket = r->element[2]->str;
            if (peerPacket) {
                TSPasteboardPacket *packet = [[TSPasteboardPacket alloc] initWithTag:@"packet" andBytes:peerPacket];
                
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
    TSStack *_pbStack;
    NSPasteboard *_generalPasteBoard;
    NSArray *_readables;
    
    void (^extractLatestCopy)(void);
    NSInteger _changeCount;
    
    TSRedisController *_redisController;
    TSEventDispatcher *_dispatcher;
    NSMutableArray *_subscriptionList;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _pbStack = [[TSStack alloc] init];
    _generalPasteBoard = [NSPasteboard generalPasteboard];
    _changeCount = [_generalPasteBoard changeCount];
    //_readables = [NSArray arrayWithObjects:[TSPasteboardPacket class] ,[NSString class], nil];
    _readables = [NSArray arrayWithObjects:[NSString class], nil];
    _dispatcher = [[TSEventDispatcher alloc] init];

    // Initialize redis controller
    _redisController = [[TSRedisController alloc] initWithDispatcher:_dispatcher];
    
    NSLog(@"Initializing block...");
    extractLatestCopy = ^(void) {
        NSInteger newChangeCount = [_generalPasteBoard changeCount];
        if (_changeCount == newChangeCount) {
            return;
        }
        _changeCount = newChangeCount;
        BOOL isPeerPaste = [_generalPasteBoard canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:@"com.trilobytesystems.plaster.uti"]];
        if (isPeerPaste) {
            NSLog(@"Packet is from a peer, discarding publish..");
            return;
        }
        NSLog(@"Reading the general pasteboard...");
        NSArray *pbContents = [_generalPasteBoard readObjectsForClasses:_readables options:nil];
        NSLog(@"Found in pasteboard : [%@]" , [pbContents objectAtIndex:0]);
        // Now we have to extract the bytes
        id packet = [pbContents objectAtIndex:0];
        NSLog(@"Processing NSString packet and publishing...");
        [_redisController publishMessage:(NSString *)packet toChannel:@"device3" withHandler:handlePeerPaste];
    };
    
    // Initialize subscription
    NSLog(@"Setting up subscriptions...");
    _subscriptionList = [[NSMutableArray alloc] initWithObjects:@"device1", @"device2", nil];
    [_redisController subscribeToChannels:_subscriptionList withHandler:handlePeerCopy andContext:(void *)_generalPasteBoard];
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
    NSLog(@"Starting pasteboard monitoring...");
    [_dispatcher dispatchTask:@"pbpoller" WithPeriod:(15 * NSEC_PER_MSEC) andHandler:extractLatestCopy];
    [self.startMenuItem setEnabled:NO];
    [self.stopMenuItem setEnabled:YES];
}

- (IBAction)stop:(id)sender {
    NSLog(@"Stopping timer and cleaning up...");
    [_dispatcher stopTask:@"pbpoller"];
    [_redisController unsubscribe];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"Quitting...");
    if ([self.stopMenuItem isEnabled]) {
        [_dispatcher stopTask:@"pbpoller"];
        [_redisController unsubscribe];
    }
    [_redisController terminate];
}

@end
