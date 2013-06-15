//
//  TSPasteboardController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPlasterController.h"
#import "TSEventDispatcher.h"
#import "TSPacketSerializer.h"
#import "TSClientIdentifier.h"
#import "TSPasteboardPacket.h"
#import "TSBase64/NSString+TSBase64.h"
#import "TSPlasterPeer.h"
#import "TSPlasterGlobals.h"

#define SESSION_BROADCAST_CHANNEL @"plaster:session:%@:broadcast"
#define SESSION_PARTICIPANTS_KEY @"plaster:session:%@:participants"
#define SESSION_PEER_CHANNEL @"plaster:session:%@:%@"

#define TEST_LOG_FILE "plaster_in.log"
#define JSON_LOG_FILE "plaster_json_out.log"

/*
struct _TSPlasterPeer {
    const char *peer;
    const char *peerAlias;
};

void printPeer(struct _TSPlasterPeer peer) {
    printf("Peer : %s\n", peer.peer);
    printf("Peer Alias : %s\n", peer.peerAlias);
}

struct _TSPlasterPeer *makePlasterPeer(NSString *peerObj) {
    struct _TSPlasterPeer *plasterPeer = (struct _TSPlasterPeer *)calloc(1, sizeof(struct _TSPlasterPeer));
    const char *temp = [peerObj UTF8String];
    char *peer = (char *)calloc(strlen(temp), sizeof(char));
    if (peer == NULL) {
        return nil;
    }
    strcpy(peer, temp);
    
    const char *peerCString = strtok(peer, "_");
    const char *aliasCString = strtok(NULL, "_");
    plasterPeer->peer = peerCString;
    plasterPeer->peerAlias = aliasCString;
    
    return plasterPeer;
}
*/

@implementation TSPlasterController {
    NSString *_clientID;
    NSPasteboard *_pb;
    NSInteger _changeCount;
    NSArray *_readables;
    NSMutableArray *_plasterPeers;
    
    TSEventDispatcher *_dispatcher;
    id <TSMessagingProvider, TSDataStoreProvider> _provider;
    NSMutableDictionary *_handlerTable;
    
    // Variables for test mode
    BOOL _testMode;
    NSString *_testLog;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider {
    self = [super init];
    if (self) {
        if (!pasteboard || !provider) {
            NSLog(@"PLASTER: INIT : The pasteboard controller needs both a valid pasteboard and a message provider.");
            return nil;
        }
        _clientID = [[TSClientIdentifier clientID] retain];
        [self setAlias:[[NSHost currentHost] localizedName]];
        [self setSessionKey:[[NSUserDefaults standardUserDefaults] stringForKey:PLASTER_SESSION_KEY_PREF]];
        _provider = [provider retain];
        _pb = [pasteboard retain];
        _dispatcher = [[TSEventDispatcher alloc] init];
        _changeCount = [_pb changeCount];
        //_readables = [NSArray arrayWithObjects:[TSPasteboardPacket class] ,[NSString class], nil];
        _readables = @[[NSString class], [NSAttributedString class]];
        [_readables retain];
        //_readables = [[NSArray alloc] initWithObjects:[NSString class], nil];
        
        // Initialize an empty list of peers.
        _plasterPeers = [[NSMutableArray alloc] init];
        _handlerTable = [[NSMutableDictionary alloc] init];
        
        // Handler : -testHandlePlasterInWithData:
        SEL handler = @selector(testHandlePlasterInWithData:);
        NSMethodSignature *signature = [TSPlasterController instanceMethodSignatureForSelector:handler];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handler];
        NSDictionary *options = [NSDictionary dictionaryWithObjects:@[self, invocation] forKeys:@[@"target", @"invocation"]];
        [_handlerTable setObject:options forKey:NSStringFromSelector(handler)];
        
        // Handler : -handlePlasterInWithData:
        handler = @selector(handlePlasterInWithData:);
        signature = [TSPlasterController instanceMethodSignatureForSelector:handler];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handler];
        options = [NSDictionary dictionaryWithObjects:@[self, invocation] forKeys:@[@"target", @"invocation"]];
        [_handlerTable setObject:options forKey:NSStringFromSelector(handler)];
        
        // Handler : -handlePeerAttachAndDetachWithData:
        handler = @selector(handlePeerAttachAndDetachWithData:);
        signature = [TSPlasterController instanceMethodSignatureForSelector:handler];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handler];
        options = [NSDictionary dictionaryWithObjects:@[self, invocation] forKeys:@[@"target", @"invocation"]];
        [_handlerTable setObject:options forKey:NSStringFromSelector(handler)];        
        
        _testMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"plaster-test-mode"];
        if (_testMode) {
            NSLog(@"PLASTER: BOOT : Test mode is enabled.");
            _testLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @TEST_LOG_FILE];
            [_testLog retain];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:_testLog]) {
                NSLog(@"PLASTER: BOOT : TEST MODE : Creating log file at path : [%@]", _testLog);
                [fileManager createFileAtPath:_testLog contents:nil attributes:nil];
            }
            NSString *jsonLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @JSON_LOG_FILE];
            if (![fileManager fileExistsAtPath:jsonLog]) {
                NSLog(@"PLASTER: BOOT : TEST MODE : Creating json log file at path : [%@]", jsonLog);
                [fileManager createFileAtPath:jsonLog contents:nil attributes:nil];
            }
            
        }
    }
    
    return self;
}

- (void)bootWithPeers:(NSUInteger)maxPeers {
    NSLog(@"PLASTER: BOOT : Booting plaster with client ID : [%@], and session ID [%@]", _clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
    
    // Publish to the plaster broadcast channel to announce self to participating peers
    NSString *broadcastChannel = [NSString stringWithFormat:SESSION_BROADCAST_CHANNEL, self.sessionKey];
    NSLog(@"PLASTER: BOOT : Publishing HELLO to broadcast channel : %@", broadcastChannel);
    NSString *hello = [NSString stringWithFormat:@"HELLO:%@", clientIdentifier];
    [_provider publishObject:hello toChannel:broadcastChannel];
        
    // Subscribe to the plaster broadcast channel to listen to broadcasts from new participants
    NSLog(@"PLASTER: BOOT : Subscribing to broadcast channel to accept new peers.");
    [_provider subscribeToChannels:@[broadcastChannel]
                           options:[self createHandlerOptionsForHandler:NSStringFromSelector(@selector(handlePeerAttachAndDetachWithData:))]];
        
    // Get the list of participants already in the current session
    NSString *participantsKey = [NSString stringWithFormat:SESSION_PARTICIPANTS_KEY, self.sessionKey];
    NSString *participants = [_provider stringValueForKey:participantsKey];
    if (!participants) {
        NSLog(@"PLASTER: BOOT : First participant for session id [%@], registering...", self.sessionKey);
        [_provider setStringValue:clientIdentifier forKey:participantsKey];
    } else {
        NSLog(@"PLASTER: BOOT : Found participants : [%@]", participants);
        NSArray *participantList = [participants componentsSeparatedByString:@":"];
        for (NSString *participant in participantList) {
            TSPlasterPeer *peer = [[TSPlasterPeer alloc] initWithPeer:participant];
            [_plasterPeers addObject:peer];
            [peer release];
        }
            
        // Add self to list, for the benefit of future participants joining this session
        NSString *updatedParticipants = [participants stringByAppendingFormat:@":%@", clientIdentifier];
        NSLog(@"PLASTER: BOOT : Updating peer list with value [%@]", updatedParticipants);
        [_provider setStringValue:updatedParticipants forKey:participantsKey];
    }
        
    // Subscribe to peers
    if ([_plasterPeers count] > 0) {
        NSLog(@"PLASTER: BOOT : Subscribing to peers...");
        NSMutableString *peerIDs = [[NSMutableString alloc] init];
        for (TSPlasterPeer *peer in _plasterPeers) {
            [peerIDs appendFormat:@" %@", [peer peerID]];
        }
        // TODO: What if subscribing to channel fails?
        [_provider subscribeToChannel:peerIDs
                               options:[self createHandlerOptionsForHandler:NSStringFromSelector(@selector(handlePlasterInWithData:))]];
        [peerIDs release];
    }

    if (_testMode) {
        NSLog(@"PLASTER : BOOT : Test mode : Subscribing to our plaster board");
        [_provider subscribeToChannels:@[_clientID]
                               options:[self createHandlerOptionsForHandler:NSStringFromSelector(@selector(testHandlePlasterInWithData:))]];
    }
    
    NSLog(@"PLASTER: BOOT : Done.");
}

- (NSDictionary *)createHandlerOptionsForHandler:(NSString *)handler {
    return [NSDictionary dictionaryWithObjects:@[handler, _handlerTable] forKeys:@[@"HANDLER_NAME", @"HANDLER_TABLE"]];
}

- (void)start {
    /*
        Start a plaster session, OR join an existing one.
    */
    NSLog(@"PLASTER: START : Starting...");
    [self bootWithPeers:10];
    NSLog(@"PLASTER: START : Starting pasteboard monitoring every 15ms");
    [self scheduleMonitorWithID:_clientID andTimeInterval:0.015];
    NSLog(@"PLASTER: START : Done.");
}

- (void)stop {
    /*
        Stop monitoring the local pasteboard.
        Unsubscribe from the broadcast channel, and from all peer paste channels.
        Indicate you are leaving the plaster session by removing yourself from the
        list of participants.
        Also empty the list of peers.
    */
    NSLog(@"PLASTER: STOP : Stopping timer and cleaning up...");
    [self invalidateMonitorWithID:_clientID];
        
    NSLog(@"PLASTER: STOP : Stopping plaster session with client ID : [%@], and session ID [%@]", _clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
    
    // Publish to the plaster broadcast channel to depart session
    NSString *broadcastChannel = [NSString stringWithFormat:SESSION_BROADCAST_CHANNEL, self.sessionKey];
    NSLog(@"PLASTER: BOOT : Publishing GOODBYE to broadcast channel : %@", broadcastChannel);
    NSString *goodbye = [NSString stringWithFormat:@"GOODBYE:%@", clientIdentifier];
    [_provider publishObject:goodbye toChannel:broadcastChannel];
    
    // Unsubscribe from both broadcast and peer channels...
    [_provider unsubscribeAll];
    NSString *participantsKey = [NSString stringWithFormat:SESSION_PARTICIPANTS_KEY, self.sessionKey];
    NSString *participants = [_provider stringValueForKey:participantsKey];
    if (!participants) {
        // Something went wrong - you are supposed to be in a session...
        NSLog(@"PLASTER: STOP : Unable to stop plaster session!");
        return;
    }
    NSLog(@"PLASTER: STOP : Found participants : [%@]", participants);
    NSMutableArray *participantList = [NSMutableArray arrayWithArray:[participants componentsSeparatedByString:@":"]];
    // If this is the only participant, then remove the session key entirely.
    if ([participantList count] == 1) {
        NSLog(@"PLASTER: STOP : Only participant, removing session key...");
        NSUInteger result = [_provider deleteKey:participantsKey];
        NSLog(@"PLASTER: STOP : Removed %ld keys.", (unsigned long)result);
    } else {
        NSLog(@"PLASTER: STOP : Removing this client from participants...");
        NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
        [participantList removeObject:clientIdentifier];
        [_provider setStringValue:[participantList componentsJoinedByString:@":"] forKey:participantsKey];
    }
        
    [_plasterPeers removeAllObjects];
    NSLog(@"PLASTER: STOP : Done.");
}

- (void)scheduleMonitorWithID:(NSString *)id andTimeInterval:(NSTimeInterval)interval {
    uint ret = [_dispatcher dispatchTask:id WithPeriod:(interval * NSEC_PER_SEC) andController:self];
    if (ret == TS_DISPATCH_ERR) {
        NSLog(@"PLASTER: Error starting Plaster monitor : Unable to create/start dispatch timer, id : %@", id);
    }
}

- (void)invalidateMonitorWithID:(NSString *)id {
    uint ret = [_dispatcher stopTask:id];
    if (ret == TS_DISPATCH_ERR) {
        NSLog(@"PLASTER: Error invalidating Plaster monitor : Unable to stop dispatch timer, id : %@", id);
    }
}

- (NSArray *)connectedPeers {
    NSMutableArray *peers = [[NSMutableArray alloc] init];
    for (TSPlasterPeer *peer in _plasterPeers) {
        [peers addObject:[peer peerAlias]];
    }
    
    return [peers autorelease];
}

- (void)disconnect:(id)sender {
    NSLog(@"PLASTER: Disconnect called!");
}

#pragma mark Timer and Handler Methods

- (void)onTimer {
    // If there are no peers to publish to, don't do anything.
    if ([_plasterPeers count] == 0) {
        return;
    }
    
    NSInteger newChangeCount = [_pb changeCount];
    if (_changeCount == newChangeCount) {
        return;
    }
    _changeCount = newChangeCount;
    
    BOOL isPeerPaste = [_pb canReadItemWithDataConformingToTypes:@[@"com.trilobytesystems.plaster.uti"]];
    if (isPeerPaste) {
        NSLog(@"PLASTER: PLASTER OUT : Packet is from a peer, discarding publish..");
        return;
    }
    NSArray *pbContents = [_pb readObjectsForClasses:_readables options:nil];
    if ([pbContents count] > 0) {
        //NSLog(@"PLASTER: PLASTER OUT : Found in pasteboard : [%@]" , [pbContents objectAtIndex:0]);
        // Now we have to extract the bytes
        id packet = [pbContents objectAtIndex:0];
        if ([packet isKindOfClass:[NSString class]]) {
            NSLog(@"PLASTER : PLASTER OUT : Processing NSString packet and publishing...");
            const char *jsonBytes = [TSPacketSerializer JSONWithStringPacket:[NSString stringWithString:packet] sender:[self alias]];
            if (jsonBytes == NULL) {
                NSLog(@"PLASTER: PLASTER OUT : Unable to complete operation, no data.");
                return;
            }
            char *bytes = (char *)calloc(strlen(jsonBytes), sizeof(char));
            if (bytes == NULL) {
                NSLog(@"PLASTER: PLASTER OUT : Unable to allocate memory for operation to complete.");
                return;
            }
            strcpy(bytes, (const char *)jsonBytes);
            [_provider publish:bytes toChannel:_clientID];
            free(bytes);
        }
    } else {
        NSLog(@"PLASTER: PLASTER OUT : Nothing retrieved from pasteboard.");
    }
}

- (void)testHandlePlasterInWithData:(char *)data {
    NSLog(@"PLASTER: TESTING : HANDLE PLASTER IN:...");
    if (data) {
        NSDictionary *payload = [TSPacketSerializer dictionaryFromJSON:data];
        TSPasteboardPacket *packet = [[TSPasteboardPacket alloc] initWithTag:@"plaster-packet-string"
                                                                      string:[payload objectForKey:@"plaster-packet-string"]];
        NSString *sender = [payload objectForKey:@"plaster-sender"];
        
        NSLog(@"PLASTER: TESTING : Obtained packet [%@]", packet);
        
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        if (!pb) {
            NSLog(@"PLASTER: TESTING : No pasteboard available...");
            [packet release];
            return;
        }
        NSLog(@"PLASTER: TESTING : Writing to [%@]", _testLog);
        NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath:_testLog];
        if (log) {
            NSLog(@"Writing to log...");
            [log truncateFileAtOffset:[log seekToEndOfFile]];
            [log writeData:[[packet packet] dataUsingEncoding:NSUTF8StringEncoding]];
            [log closeFile];
            // Show test notification
            // Notify the user.
            NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
            [userNotificationCenter removeAllDeliveredNotifications];
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            [notification setTitle:@"Plaster Test Notification"];
            [notification setSubtitle:@"You have recieved a new plaster from :"];
            NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
            [notification setInformativeText:pasteInfo];
            [userNotificationCenter deliverNotification:notification];

        }
        [packet release];
    } else {
        NSLog(@"Data was nil : %s", data);
    }
    
    return;
}

- (void)handlePlasterInWithData:(char *)data {
    printf("PLASTER: HANDLE PLASTER IN: %s\n", data);
    NSDictionary *payload = nil;
    if (data) {
        payload = [TSPacketSerializer dictionaryFromJSON:data];
        if (payload) {
            TSPasteboardPacket *packet = [[TSPasteboardPacket alloc] initWithTag:@"plaster-packet-string"
                                                                          string:[payload objectForKey:@"plaster-packet-string"]];
            NSString *sender = [payload objectForKey:@"plaster-sender"];
            NSLog(@"PLASTER: PLASTER IN : Obtained packet [%@]", packet);
            
            NSPasteboard *pb = [NSPasteboard generalPasteboard];
            if (!pb) {
                NSLog(@"PLASTER: PLASTER IN : No pasteboard available...");
                [packet release];
                return;
            }
            NSLog(@"Pasting...");
            [pb clearContents];
            BOOL ok = [pb writeObjects:@[packet]];
            if (ok) {
                NSLog(@"PLASTER: PLASTER IN : Peer copy successfully written to local pasteboard.");
                // Notify the user.
                NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
                [self sendNotificationWithSubtitle:@"You have recieved a new plaster from :" informativeText:pasteInfo];
            }
            [packet release];
            return;
        }
    }
    
    NSLog(@"PLASTER: HANDLE IN : Data(%s) or payload(%@) was null. ", data, payload);
    return;
}

/*
 This method registers new participants for a given session.
 It is a callback handler for processing messages arriving in
 the session broadcast channel.
 The data passed through, is the CLIENT_ID of the participant
 broadcasting it's presence. The function logs this value and
 adds this participant to it's liste of internal peers.
 
 It enables the plaster client to be aware of future additions
 to the plaster session.
*/
- (void)handlePeerAttachAndDetachWithData:(char *)data {
    if (data) {
        NSString *str = [NSString stringWithCString:data encoding:NSUTF8StringEncoding];
        NSLog(@"PLASTER: PEER ATTACH/DETACH : %@", str);
        
        if ([str hasPrefix:@"HELLO:"]) {
            NSLog(@"PLASTER: HANDLE PEER : Processing HELLO from peer with ID [%@].", str);
            
            NSString *peer = [str substringFromIndex:6];
            TSPlasterPeer *plpeer = [[TSPlasterPeer alloc] initWithPeer:peer];
            if ([[plpeer peerAlias] isEqualToString:[self alias]]) {
                NSLog(@"Ignoring hello from self.");
                [plpeer release];
                return;
            }
            
            // Now subscribe to this new peer...
            [_provider subscribeToChannel:[plpeer peerID]
                                  options:[self createHandlerOptionsForHandler:NSStringFromSelector(@selector(handlePlasterInWithData:))]];
            if (![_plasterPeers containsObject:plpeer]) {
                [_plasterPeers addObject:plpeer];
                //If configured, send a notification...
                NSString *subtitle = [NSString stringWithFormat:@"%@ has joined.", [plpeer peerAlias]];
                [self sendNotificationWithSubtitle:subtitle informativeText:nil];
            }
            [plpeer release];            
        } else if ([str hasPrefix:@"GOODBYE:"]) {
            NSLog(@"PLASTER: HANDLE PEER : Processing GOODBYE from peer with ID [%@].", str);
            
            NSString *peer = [str substringFromIndex:8];
            TSPlasterPeer *plpeer = [[TSPlasterPeer alloc] initWithPeer:peer];
            if ([[plpeer peerAlias] isEqualToString:[self alias]]) {
                NSLog(@"Ignoring goodbye from self.");
                [plpeer release];
                return;
            }
            
            if ([_plasterPeers containsObject:plpeer]) {
                [_plasterPeers removeObject:plpeer];
                //If configured, send a notification...
                NSString *subtitle = [NSString stringWithFormat:@"%@ has left.", [plpeer peerAlias]];
                [self sendNotificationWithSubtitle:subtitle informativeText:nil];
            }
            [plpeer release];
        }
        
    }
    return;
}

#pragma mark Notification Methods

- (void)sendNotificationWithSubtitle:(NSString *)subtitle informativeText:(NSString *)text {
    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [userNotificationCenter removeAllDeliveredNotifications];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"Plaster Notification"];
    [notification setSubtitle:subtitle];
    if (text) {
        [notification setInformativeText:text];        
    }
    [userNotificationCenter deliverNotification:notification];
}

- (void)dealloc {
    [_clientID release];
    [_plasterPeers release];
    [_provider release];
    [_pb release];
    [_dispatcher release];
    [_readables release];
    [_handlerTable release];
    if (_testMode) {
        [_testLog release];
    }
    [super dealloc];
}

@end
