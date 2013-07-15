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
#import "TSPlasterString.h"
#import "TSPlasterImage.h"

#define SESSION_BROADCAST_CHANNEL @"plaster:session:%@:broadcast"
#define SESSION_PEERS_KEY @"plaster:session:%@:peers"
NSString *const TSPlasterSessionFileTransferKey = @"plaster:session:%@:file:%@";

#define TEST_LOG_FILE "plaster_in.log"
#define JSON_LOG_FILE "plaster_json_out.log"

static double MB = 1024 * 1024;

@implementation TSPlasterController {
    NSString *_clientID;
    NSPasteboard *_pb;
    NSMutableArray *_plasterPeers;
    
    TSEventDispatcher *_dispatcher;
    id <TSMessagingProvider, TSDataStoreProvider> _provider;
    NSMutableDictionary *_handlerTable;
    
    // Notification variables
    NSUserNotificationCenter *_userNotificationCenter;

    
    // Variables for test mode
    BOOL _testMode;
    NSString *_testLog;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider {
    self = [super init];
    if (self) {
        if (!pasteboard || !provider) {
            DLog(@"PLASTER: INIT : The pasteboard controller needs both a valid pasteboard and a message provider.");
            return nil;
        }
        _clientID = [[TSClientIdentifier clientID] retain];
        NSString *aliasPref = [[NSUserDefaults standardUserDefaults] stringForKey:TSPlasterDeviceName];
        if (aliasPref) {
            [self setAlias:aliasPref];
        } else {
            [self setAlias:[[NSHost currentHost] localizedName]];            
        }
        //[self setSessionKey:[[NSUserDefaults standardUserDefaults] stringForKey:PLASTER_SESSION_KEY_PREF]];
        [self setSessionKey:nil];
        _userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        _userNotificationCenter.delegate = self;

        _provider = [provider retain];
        _pb = [pasteboard retain];
        _dispatcher = [[TSEventDispatcher alloc] init];
        _changeCount = [_pb changeCount];
        
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
        
        // Handler : -handlePlasterNotificationForDataWithSize:
        handler = @selector(handlePlasterNotificationForDataWithSize:);
        signature = [TSPlasterController instanceMethodSignatureForSelector:handler];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handler];
        options = [NSDictionary dictionaryWithObjects:@[self, invocation] forKeys:@[@"target", @"invocation"]];
        [_handlerTable setObject:options forKey:NSStringFromSelector(handler)];
        
        _testMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"plaster-test-mode"];
        if (_testMode) {
            DLog(@"PLASTER: BOOT : Test mode is enabled.");
            _testLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @TEST_LOG_FILE];
            [_testLog retain];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:_testLog]) {
                DLog(@"PLASTER: BOOT : TEST MODE : Creating log file at path : [%@]", _testLog);
                [fileManager createFileAtPath:_testLog contents:nil attributes:nil];
            }
            NSString *jsonLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @JSON_LOG_FILE];
            if (![fileManager fileExistsAtPath:jsonLog]) {
                DLog(@"PLASTER: BOOT : TEST MODE : Creating json log file at path : [%@]", jsonLog);
                [fileManager createFileAtPath:jsonLog contents:nil attributes:nil];
            }
            
        }
    }
    
    return self;
}

- (void)bootWithPeers:(NSUInteger)maxPeers {
    NSUInteger result = EXIT_FAILURE;
    DLog(@"PLASTER: BOOT : Booting plaster with client ID : [%@], and session ID [%@]", _clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
    
    // Publish to the plaster broadcast channel to announce self to participating peers
    NSString *broadcastChannel = [NSString stringWithFormat:SESSION_BROADCAST_CHANNEL, self.sessionKey];
    DLog(@"PLASTER: BOOT : Publishing HELLO to broadcast channel : %@", broadcastChannel);
    NSString *hello = [NSString stringWithFormat:@"HELLO:%@", clientIdentifier];
    result = [_provider publishObject:hello channel:broadcastChannel options:nil];
    NSAssert(result == EXIT_SUCCESS, @"PLASTER: FATAL : Unable to publish to broadcast channel %@", broadcastChannel);
        
    // Subscribe to the plaster broadcast channel to listen to broadcasts from new participants
    DLog(@"PLASTER: BOOT : Subscribing to broadcast channel to accept new peers.");
    result = [_provider subscribeToChannel:broadcastChannel
                           options:[self handlerOptionsForHandler:NSStringFromSelector(@selector(handlePeerAttachAndDetachWithData:))]];
    NSAssert(result == EXIT_SUCCESS, @"PLASTER: FATAL : Unable to subscribe to broadcast channel %@", broadcastChannel);
    
        
    // Get the list of participants already in the current session
    NSString *peersKey = [NSString stringWithFormat:SESSION_PEERS_KEY, self.sessionKey];
    NSString *peers = [_provider stringValueForKey:peersKey];
    if (!peers) {
        DLog(@"PLASTER: BOOT : First participant for session id [%@], registering...", self.sessionKey);
        result = [_provider setStringValue:clientIdentifier forKey:peersKey];
        NSAssert(result == EXIT_SUCCESS, @"PLASTER: FATAL : Unable to register as first participant with key %@", peersKey);
    } else {
        DLog(@"PLASTER: BOOT : Found peers : [%@]", peers);
        NSArray *peerList = [peers componentsSeparatedByString:@":"];
        for (NSString *peerID in peerList) {
            TSPlasterPeer *peer = [[TSPlasterPeer alloc] initWithPeer:peerID];
            [_plasterPeers addObject:peer];
            [peer release];
        }
            
        // Add self to list, for the benefit of future participants joining this session
        NSString *updatedPeers = [peers stringByAppendingFormat:@":%@", clientIdentifier];
        DLog(@"PLASTER: BOOT : Updating peer list with value [%@]", updatedPeers);
        result = [_provider setStringValue:updatedPeers forKey:peersKey];
        NSAssert(result == EXIT_SUCCESS, @"PLASTER: FATAL : Unable to add to peers key %@", peersKey);
    }
        
    // Subscribe to peers
    if ([_plasterPeers count] > 0) {
        DLog(@"PLASTER: BOOT : Subscribing to peers...");
        NSMutableString *peerIDs = [[NSMutableString alloc] init];
        for (TSPlasterPeer *peer in _plasterPeers) {
            [peerIDs appendFormat:@" %@", [peer peerID]];
        }
        // TODO: What if subscribing to channel fails?
        result = [_provider subscribeToChannel:peerIDs
                               options:[self handlerOptionsForHandler:NSStringFromSelector(@selector(handlePlasterInWithData:))]];
        NSAssert(result == EXIT_SUCCESS, @"PLASTER: FATAL : Unable to subscribe to plaster peers  : %@", peerIDs);
        [peerIDs release];
    }

    if (_testMode) {
        DLog(@"PLASTER: BOOT : Test mode : Subscribing to our plaster board");
        [_provider subscribeToChannel:_clientID
                               options:[self handlerOptionsForHandler:NSStringFromSelector(@selector(testHandlePlasterInWithData:))]];
    }
    
    DLog(@"PLASTER: BOOT : Done.");
}

- (NSDictionary *)handlerOptionsForHandler:(NSString *)handler {
    return [NSDictionary dictionaryWithObjects:@[handler, _handlerTable] forKeys:@[@"HANDLER_NAME", @"HANDLER_TABLE"]];
}

- (void)start {
    NSAssert(_sessionKey != nil, @"PLASTER: FATAL : Will not start without a valid session key");
    /*
        Start a plaster session, OR join an existing one.
    */
    DLog(@"PLASTER: START : Starting...");
    self.started = YES;
    self.running = YES;
    [self bootWithPeers:10];
    DLog(@"PLASTER: START : Starting pasteboard monitoring every 100ms");
    [self scheduleMonitorWithID:_clientID andTimeInterval:0.100];
    DLog(@"PLASTER: START : Done.");
}

- (void)stop {
    self.started = NO;
    self.running = NO;
    /*
        Stop monitoring the local pasteboard.
        Unsubscribe from the broadcast channel, and from all peer paste channels.
        Indicate you are leaving the plaster session by removing yourself from the
        list of participants.
        Also empty the list of peers.
    */
    NSUInteger result = EXIT_FAILURE;
    DLog(@"PLASTER: STOP : Stopping timer and cleaning up...");
    [self invalidateMonitorWithID:_clientID];
        
    DLog(@"PLASTER: STOP : Stopping plaster session with client ID : [%@], and session ID [%@]", _clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
    
    // Publish to the plaster broadcast channel to depart session
    NSString *broadcastChannel = [NSString stringWithFormat:SESSION_BROADCAST_CHANNEL, self.sessionKey];
    DLog(@"PLASTER: BOOT : Publishing GOODBYE to broadcast channel : %@", broadcastChannel);
    NSString *goodbye = [NSString stringWithFormat:@"GOODBYE:%@", clientIdentifier];
    result = [_provider publishObject:goodbye channel:broadcastChannel options:nil];
    NSAssert(result == EXIT_SUCCESS, @"PLASTER: STOP : Unable to broadcast goodbye to channel : %@", broadcastChannel);
    
    // Unsubscribe from both broadcast and peer channels...
    [_provider unsubscribeAll];
    NSString *peersKey = [NSString stringWithFormat:SESSION_PEERS_KEY, self.sessionKey];
    NSString *peers = [_provider stringValueForKey:peersKey];
    if (!peers) {
        // Something went wrong - you are supposed to be in a session...
        DLog(@"PLASTER: STOP : Unable to stop plaster session!");
        return;
    }
    DLog(@"PLASTER: STOP : Found peers : [%@]", peers);
    NSMutableArray *peerList = [NSMutableArray arrayWithArray:[peers componentsSeparatedByString:@":"]];
    // If this is the only participant, then remove the session key entirely.
    if ([peerList count] == 1) {
        DLog(@"PLASTER: STOP : Only participant, removing session key...");
        result = [_provider deleteKey:peersKey];
        NSAssert(result == EXIT_SUCCESS, @"PLASTER: STOP : Unable to delete session key : %@", peersKey);
        //DLog(@"PLASTER: STOP : Removed %ld keys.", (unsigned long)result);
    } else {
        DLog(@"PLASTER: STOP : Removing this client from peers...");
        [peerList removeObject:clientIdentifier];
        result = [_provider setStringValue:[peerList componentsJoinedByString:@":"] forKey:peersKey];
        NSAssert(result == EXIT_SUCCESS, @"PLASTER: STOP : Unable to remove this peer from session : %@", peersKey);
    }
    
    [_plasterPeers removeAllObjects];
    DLog(@"PLASTER: STOP : Done.");
}

- (void)scheduleMonitorWithID:(NSString *)id andTimeInterval:(NSTimeInterval)interval {
    uint ret = [_dispatcher dispatchTask:id WithPeriod:(interval * NSEC_PER_SEC) andController:self];
    if (ret == TS_DISPATCH_ERR) {
        DLog(@"PLASTER: Error starting Plaster monitor : Unable to create/start dispatch timer, id : %@", id);
    }
}

- (void)invalidateMonitorWithID:(NSString *)id {
    uint ret = [_dispatcher stopTask:id];
    if (ret == TS_DISPATCH_ERR) {
        DLog(@"PLASTER: Error invalidating Plaster monitor : Unable to stop dispatch timer, id : %@", id);
    }
}

- (NSArray *)connectedPeers {
    NSMutableArray *peers = [[NSMutableArray alloc] init];
    for (TSPlasterPeer *peer in _plasterPeers) {
        [peers addObject:[peer peerAlias]];
    }
    
    return [peers autorelease];
}

#pragma mark Timer and Handler Methods

- (void)plaster:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    DLog(@"PLASTER: Handling plaster from external application.");
    if (!self.running) {
        DLog(@"PLASTER: Plaster is not running.");
        *error = @"PLASTER: Plaster is not running.";
        return;
    }
    if (self.sessionKey && self.alias) {
        [self plaster:pboard];
    } else {
        *error = @"PLASTER: Unable to complete copy operation. Invalid session key or alias.";
    }
    return;
}

- (void)onTimer {
    // If there are no peers to publish to, don't do anything.
    if ([_plasterPeers count] == 0) {
        return;
    }
    
    // if Plaster just started, ignore existing pasteboard content
    if (self.started) {
        DLog(@"PLASTER: PLASTER OUT : Clearing stale content...");
        self.started = NO;
        [_pb clearContents];
        return;
    }
    
    NSInteger newChangeCount = [_pb changeCount];
    if (self.changeCount == newChangeCount) {
        return;
    }
    [self setChangeCount:newChangeCount];
    
    BOOL isPeerPaste = [_pb canReadItemWithDataConformingToTypes:@[PLASTER_STRING_UTI, PLASTER_IMAGE_UTI]];
    if (isPeerPaste) {
        DLog(@"PLASTER: PLASTER OUT : Packet is from a peer, discarding publish..");
        return;
    }
    
    [self plaster:_pb];
}

- (void)plaster:(NSPasteboard *)pboard {
    BOOL allowOutFiles = [[_sessionProfile objectForKey:TSPlasterOutAllowFiles] boolValue];
    if (allowOutFiles) {
        DLog(@"PLASTER: PLASTER OUT : Allowing files to be plastered out.");
        NSArray *classes = @[[NSURL class]];
        NSDictionary *options = [NSDictionary dictionaryWithObject:@YES forKey:NSPasteboardURLReadingFileURLsOnlyKey];
        if ([pboard canReadObjectForClasses:classes options:options]) {
            @autoreleasepool {
                DLog(@"PLASTER: PLASTER OUT : File URLS can be obtained from pasteboard.");
                NSArray *fileURLs = [pboard readObjectsForClasses:classes options:options];
                DLog(@"PLASTER: PLASTER OUT : Read URLs : %@", fileURLs);
                // TODO : Convert to chunked & asynchronous implementation!
                NSError *error;
                NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:fileURLs[0] error:&error];
                if (error) {
                    DLog(@"PLASTER: PLASTER OUT : Error occured accessing file URL : %@", error);
                    return;
                }
                if (handle) {
                    NSData *contents = [handle readDataToEndOfFile];
                    if (contents) {
                        unsigned long length = ([contents length] / (1024 * 1024));
                        DLog(@"PLASTER : PLASTER OUT : Read file contents with length : %luMB", length);
                        if (length > 102) {
                            DLog(@"PLASTER: PLASTER OUT : Will not transmit files of length greater than 500MB.");
                            contents = nil;
                            return;
                        }
                        // We prepare a notification of type content_identifier#length and broadcast this to all peers
                        // This will allow the peers to decide whether they want to fetch the content
                        // The content key will expire in 10 minutes
                        NSString *fileTransferID = [TSClientIdentifier createUUID];
                        NSString *plasterNotification = [NSString stringWithFormat:@"FILE:%@#%lu", fileTransferID, length];
                        DLog(@"PLASTER: PLASTER OUT : Notifying peers with notification string : %@", plasterNotification);
                        const char *notification = [TSPacketSerializer JSONWithNotificationPacket:plasterNotification sender:self.alias];
                        [self transmitJSON:notification];
                        
                        const char *jsonBytes = NULL;
                        jsonBytes = [TSPacketSerializer JSONWithDataPacket:contents sender:self.alias];
                        if (jsonBytes == NULL) {
                            DLog(@"PLASTER: PLASTER OUT : Unable to complete operation, no data.");
                            return;
                        }
                        NSString *fileTransferKey = [NSString stringWithFormat:TSPlasterSessionFileTransferKey, self.sessionKey, fileTransferID];
                        DLog(@"PLASTER: PLASTER OUT : Creating key for file transfer : %@", fileTransferKey);
                        [_provider setByteValue:jsonBytes forKey:fileTransferKey];
                        //[self transmitJSON:jsonBytes];
                        DLog(@"PLASTER: PLASTER OUT : File transmission initiated.");
                    }
                }
            }
            
            return;
        }
    }
    NSMutableArray *readables = [NSMutableArray array];
    BOOL allowOutImages = [[_sessionProfile objectForKey:TSPlasterOutAllowImages] boolValue];
    if (allowOutImages) {
        DLog(@"PLASTER: PLASTER OUT : Allowing images to be plastered out.");
        [readables addObject:[NSImage class]];
    }
    BOOL allowOutText = [[_sessionProfile objectForKey:TSPlasterOutAllowText] boolValue];
    if (allowOutText) {
        DLog(@"PLASTER: PLASTER OUT : Allowing text to be plastered out.");
        [readables addObjectsFromArray:@[[NSAttributedString class], [NSString class]]];
    }
    NSArray *pbContents = [pboard readObjectsForClasses:readables options:nil];
    DLog(@"PLASTER: Read %ld items from pasteboard.", (unsigned long)[pbContents count]);
    if ([pbContents count] > 0) {
        const char *jsonBytes = NULL;
        @autoreleasepool {
            // Now we have to extract the bytes
            id packet = [pbContents objectAtIndex:0];
            if ([packet isKindOfClass:[NSString class]] || [packet isKindOfClass:[NSAttributedString class]]) {
                DLog(@"PLASTER : PLASTER OUT : Processing NSString packet and publishing...");
                jsonBytes = [TSPacketSerializer JSONWithTextPacket:packet sender:[self alias]];
            } else if ([packet isKindOfClass:[NSImage class]]) {
                DLog(@"PLASTER : PLASTER OUT : Processing NSImage packet and publishing...");
                jsonBytes = [TSPacketSerializer JSONWithImagePacket:packet  sender:[self alias]];
            }
            if (jsonBytes == NULL) {
                DLog(@"PLASTER: PLASTER OUT : Unable to complete operation, no data.");
                return;
            }
        }

        [self transmitJSON:jsonBytes];
    } else {
        DLog(@"PLASTER: PLASTER OUT : Nothing retrieved from pasteboard.");
    }    
}

- (void)transmitJSON:(const char *)json {
    size_t length = strlen(json);
    if (length > (2 * MB)) {
        DLog(@"PLASTER: PLASTER OUT : Plaster size > 2MB, requesting sent notification...");
        NSMutableDictionary *options = [[NSMutableDictionary alloc]
                                        initWithDictionary:[_handlerTable objectForKey:@"handlePlasterNotificationForDataWithSize:"]];
        [options setObject:[NSNumber numberWithLong:length] forKey:@"packetSize"];
        [_handlerTable setObject:options forKey:@"handlePlasterNotificationForDataWithSize:"];
        
        [_provider publish:json channel:_clientID
                   options:[self handlerOptionsForHandler:@"handlePlasterNotificationForDataWithSize:"]];
        [options release];
    } else {
        [_provider publish:json channel:_clientID options:nil];
    }
    return;
}

- (void)testHandlePlasterInWithData:(char *)data {
    DLog(@"PLASTER: TEST : HANDLE PLASTER IN:");
    NSDictionary *payload = nil;
    if (data) {
        payload = [TSPacketSerializer dictionaryFromJSON:data];
        if (payload) {
            NSString *type = [payload objectForKey:TSPlasterJSONKeyForPlasterType];
            if ([type isEqualToString:TSPlasterTypeText]) {
                TSPasteboardPacket *packet = [[TSPasteboardPacket alloc] initWithTag:TSPlasterPacketText
                                                                              string:[payload objectForKey:TSPlasterPacketText]];
                //NSString *sender = [payload objectForKey:PLASTER_SENDER_JSON_KEY];
                
                DLog(@"PLASTER: TESTING : Obtained packet [%@]", packet);
                
                NSPasteboard *pb = [NSPasteboard generalPasteboard];
                if (!pb) {
                    DLog(@"PLASTER: TESTING : No pasteboard available...");
                    [packet release];
                    return;
                }
                DLog(@"PLASTER: TESTING : Writing to [%@]", _testLog);
                NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath:_testLog];
                if (log) {
                    DLog(@"Writing to log...");
                    [log truncateFileAtOffset:[log seekToEndOfFile]];
                    [log writeData:[[packet packet] dataUsingEncoding:NSUTF8StringEncoding]];
                    [log closeFile];
                    // Show test notification
                    /*
                    BOOL notify = [[NSUserDefaults standardUserDefaults] boolForKey:PLASTER_NOTIFY_PLASTERS_PREF];
                    if (notify) {
                        NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
                        [self sendNotificationWithSubtitle:@"[TEST] You have recieved a new plaster from :" informativeText:pasteInfo];
                    }
                    */
                }
                [packet release];
                return;
            } else if ([type isEqualToString:TSPlasterTypeImage]) {
                DLog(@"PLASTER: TESTING: Processing image packet...");
                return;
            }
        }
    }
    
    DLog(@"PLASTER: HANDLE IN : Data(%s) or payload(%@) was null. ", data, payload);
    return;
}

- (void)handlePlasterInWithData:(char *)data {
    DLog(@"PLASTER: HANDLE IN :");
    NSDictionary *payload = nil;
    if (data) {
        payload = [TSPacketSerializer dictionaryFromJSON:data];
        if (payload) {
            BOOL allowFileType = [[_sessionProfile objectForKey:TSPlasterAllowFiles] boolValue];
            BOOL allowTextType = [[_sessionProfile objectForKey:TSPlasterAllowText] boolValue];
            BOOL allowImageType = [[_sessionProfile objectForKey:TSPlasterAllowImages] boolValue];
            
            NSString *type = [payload objectForKey:TSPlasterJSONKeyForPlasterType];
            id packet = nil;
            
            if ([type isEqualToString:TSPlasterTypeText]) {
                if (!allowTextType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming text-type plasters.");
                    return;
                }
                DLog(@"PLASTER: HANDLE IN : Processing text packet...");
                packet = [[TSPlasterString alloc] initWithString:[payload objectForKey:TSPlasterPacketText]];
            } else if ([type isEqualToString:TSPlasterTypeImage]) {
                if (!allowImageType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming image-type plasters.");
                    return;                    
                }
                DLog(@"PLASTER: HANDLE IN : Processing image packet...");
                packet = [[TSPlasterImage alloc] initWithImage:[payload objectForKey:TSPlasterPacketImage]];
            } else if ([type isEqualToString:TSPlasterTypeFile]) {
                if (!allowFileType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming file-type plasters.");
                    return;
                }
            }
            
            if (!packet) {
                DLog(@"PLASTER: HANDLE IN : Unable to initialize text or image packet.");
                return;
            }
            DLog(@"PLASTER: HANDLE IN : Obtained packet [%@]", packet);
            
            NSString *sender = [payload objectForKey:TSPlasterJSONKeyForSenderID];
            
            // Figure out how the user wants to write out the packet - pasteboard or file
            NSString *mode = [_sessionProfile objectForKey:TSPlasterMode];
            if ([mode isEqualToString:TSPlasterModePasteboard]) {
                DLog(@"PLASTER: HANDLE IN : Operating in pasteboard mode...");
                NSPasteboard *pb = [NSPasteboard generalPasteboard];
                if (!pb) {
                    DLog(@"PLASTER: PLASTER IN : No pasteboard available...");
                    [packet release];
                    return;
                }
                DLog(@"PLASTER: HANDLE IN : Pasting...");
                [pb clearContents];
                BOOL ok = [pb writeObjects:@[packet]];
                if (ok) {
                    DLog(@"PLASTER: HANDLE IN : Peer copy successfully written to local pasteboard.");
                    // Notify the user.
                    BOOL notify = [[_sessionProfile objectForKey:TSPlasterNotifyPlasters] boolValue];
                    if (notify) {
                        NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
                        [self sendNotificationWithSubtitle:@"You have recieved a new plaster from :" informativeText:pasteInfo];
                    }
                }
            } else if ([mode isEqualToString:TSPlasterModeFile]) {
                DLog(@"PLASTER: HANDLE IN : Operating in file mode...");
                // Since this is just ordinary clipboard text and image data, generate a file name
                NSFileManager *fm = [NSFileManager defaultManager];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSDate *now = [[NSDate alloc] init];
                NSString *date = [dateFormatter stringFromDate:now];
                [now release];
                [dateFormatter release];
                
                NSString *plasterFolderPath = [_sessionProfile objectForKey:TSPlasterFolderPath];
                NSString *plasterFileName = nil;
                NSData *blob = nil;
                if ([type isEqualToString:TSPlasterTypeText]) {
                    plasterFileName = [NSString stringWithFormat:@"%@_%@.txt", date, sender];
                    blob = [packet dataUsingEncoding:NSUTF8StringEncoding];
                } else if ([type isEqualToString:TSPlasterTypeImage]) {
                    plasterFileName = [NSString stringWithFormat:@"%@_%@.tiff", date, sender];
                    blob = [packet TIFFRepresentation];
                }
                if (!blob) {
                    DLog(@"PLASTER: HANDLE IN : Error obtaining data representations for incoming plaster.");
                    [packet release];
                    return;
                }
                NSString *outputPath = [NSString pathWithComponents:@[plasterFolderPath, plasterFileName]];
                DLog(@"PLASTER: HANDLE IN : Dumping incoming plaster to path : %@", outputPath);
                if (![fm createFileAtPath:outputPath contents:blob attributes:nil]) {
                    DLog(@"PLASTER: HANDLE IN : Unable to create content file at path : %@", outputPath);
                } else {
                    BOOL notify = [[_sessionProfile objectForKey:TSPlasterNotifyPlasters] boolValue];
                    if (notify) {
                        NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
                        [self sendNotificationWithSubtitle:@"You have recieved a new file from :" informativeText:pasteInfo];
                    }
                }
            }
            
            [packet release];
            return;            
        }
    }
    
    DLog(@"PLASTER: HANDLE IN : Data(%s) or payload(%@) was null. ", data, payload);
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
        DLog(@"PLASTER: PEER ATTACH/DETACH : %@", str);
        
        if ([str hasPrefix:@"HELLO:"]) {
            DLog(@"PLASTER: HANDLE PEER : Processing HELLO from peer with ID [%@].", str);
            
            NSString *peer = [str substringFromIndex:6];
            TSPlasterPeer *plpeer = [[TSPlasterPeer alloc] initWithPeer:peer];
            if ([[plpeer peerAlias] isEqualToString:[self alias]]) {
                DLog(@"Ignoring hello from self.");
                [plpeer release];
                return;
            }
            
            // Now subscribe to this new peer...
            [_provider subscribeToChannel:[plpeer peerID]
                                  options:[self handlerOptionsForHandler:NSStringFromSelector(@selector(handlePlasterInWithData:))]];
            if (![_plasterPeers containsObject:plpeer]) {
                @synchronized(self) {
                    [_plasterPeers addObject:plpeer];
                }
                //If configured, send a notification...
                BOOL notify = [[_sessionProfile objectForKey:TSPlasterNotifyJoins] boolValue];
                if (notify) {
                    NSString *subtitle = [NSString stringWithFormat:@"'%@' has joined session [%@]", [plpeer peerAlias], [_sessionProfile objectForKey:TSPlasterProfileName]];
                    [self sendNotificationWithSubtitle:subtitle informativeText:nil];
                }
            }
            [plpeer release];            
        } else if ([str hasPrefix:@"GOODBYE:"]) {
            DLog(@"PLASTER: HANDLE PEER : Processing GOODBYE from peer with ID [%@].", str);
            
            NSString *peer = [str substringFromIndex:8];
            TSPlasterPeer *plpeer = [[TSPlasterPeer alloc] initWithPeer:peer];
            if ([[plpeer peerAlias] isEqualToString:[self alias]]) {
                DLog(@"Ignoring goodbye from self.");
                [plpeer release];
                return;
            }
            
            if ([_plasterPeers containsObject:plpeer]) {
                @synchronized(self) {
                    [_plasterPeers removeObject:plpeer];
                }
                //If configured, send a notification...
                BOOL notify = [[_sessionProfile objectForKey:TSPlasterNotifyDepartures] boolValue];
                if (notify) {
                    NSString *subtitle = [NSString stringWithFormat:@"'%@' has left session [%@]", [plpeer peerAlias], [_sessionProfile objectForKey:TSPlasterProfileName]];
                    [self sendNotificationWithSubtitle:subtitle informativeText:nil];
                }
            }
            [plpeer release];
        }
        
    }
    return;
}

- (void)handlePlasterNotificationForDataWithSize:(NSNumber *)size {
    DLog(@"Plaster: HANDLE SENT NOTIFICATION : For size : %@", size);
    
    return;
}

#pragma mark Notification Methods

- (void)sendNotificationWithSubtitle:(NSString *)subtitle informativeText:(NSString *)text {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"Plaster Notification"];
    [notification setSubtitle:subtitle];
    if (text) {
        [notification setInformativeText:text];        
    }
    [_userNotificationCenter deliverNotification:notification];
    [notification release];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    if ([[notification title] isEqualToString:@"Plaster Notification"]) {
        return YES;        
    }
    
    return NO;
}

#pragma mark Handle Zombie Sessions

/*
    This method tries to remove stale participation in the provided sessions. 
    This happens when the client crashes/fails before disconnecting from a session
    and cleaning up.
*/
- (void)disconnectFromSessions:(NSArray *)sessions {
    NSUInteger result;
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", _clientID, [self alias]];
    for (NSString *sessionKey in sessions) {
        NSString *peersKey = [NSString stringWithFormat:SESSION_PEERS_KEY, sessionKey];
        NSString *peers = [_provider stringValueForKey:peersKey];
        if (!peers) {
            DLog(@"PLASTER: DISCONNECT FROM SESSIONS : No live session found with key : %@", peersKey);
            continue;
        }
        DLog(@"PLASTER: DISCONNECT FROM SESSIONS : Found peers : [%@]", peers);
        NSMutableArray *peerList = [NSMutableArray arrayWithArray:[peers componentsSeparatedByString:@":"]];
        [peerList removeObject:clientIdentifier];
        // If this is the only participant, then remove the session key entirely.
        if ([peerList count] == 0) {
            DLog(@"PLASTER: DISCONNECT FROM SESSIONS : Only participant, removing session key...");
            result = [_provider deleteKey:peersKey];
            NSAssert(result == EXIT_SUCCESS, @"PLASTER: STOP : Unable to delete session key : %@", peersKey);
        } else {
            DLog(@"PLASTER: DISCONNECT FROM SESSIONS : Removing stale client from peers...");
            result = [_provider setStringValue:[peerList componentsJoinedByString:@":"] forKey:peersKey];
            NSAssert(result == EXIT_SUCCESS, @"PLASTER: DISCONNECT FROM SESSIONS : Unable to disconnect from session : %@", peersKey);
        }
    }
}

- (void)dealloc {
    [_clientID release];
    [_plasterPeers release];
    [_provider release];
    [_pb release];
    [_dispatcher release];
    [_handlerTable release];
    if (_testMode) {
        [_testLog release];
    }
    [super dealloc];
}

@end
