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
#import "TSPlasterFile.h"

#define SESSION_BROADCAST_CHANNEL @"plaster:session:%@:broadcast"
#define SESSION_PEERS_KEY @"plaster:session:%@:peers"
NSString *const TSPlasterSessionFileTransferKey = @"plaster:session:%@:file:%@";
NSString *const TSPlasterSessionFileNotificationPattern = @"FILE:%@#%@#%lu";

#define TEST_LOG_FILE "plaster_in.log"
#define JSON_LOG_FILE "plaster_json_out.log"

static const double MB = 1024 * 1024;

@implementation TSPlasterController {
    //NSString *_clientID;
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
    
    NSString *TSPlasterTemporaryDirectory;
    NSOperationQueue *_operationQueue;
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
        
        // Handler : -handlePlasterNotificationForFileWithOptions:
        handler = @selector(handlePlasterNotificationForFileWithOptions:);
        signature = [TSPlasterController instanceMethodSignatureForSelector:handler];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handler];
        options = [NSDictionary dictionaryWithObjects:@[self, invocation] forKeys:@[@"target", @"invocation"]];
        [_handlerTable setObject:options forKey:NSStringFromSelector(handler)];
        
        _testMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"plaster-test-mode"];
        if (_testMode) {
            DLog(@"PLASTER: INIT : Test mode is enabled.");
            _testLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @TEST_LOG_FILE];
            [_testLog retain];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:_testLog]) {
                DLog(@"PLASTER: INIT : TEST MODE : Creating log file at path : [%@]", _testLog);
                [fileManager createFileAtPath:_testLog contents:nil attributes:nil];
            }
            NSString *jsonLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @JSON_LOG_FILE];
            if (![fileManager fileExistsAtPath:jsonLog]) {
                DLog(@"PLASTER: INIT : TEST MODE : Creating json log file at path : [%@]", jsonLog);
                [fileManager createFileAtPath:jsonLog contents:nil attributes:nil];
            }
            
        }
        NSLog(@"PLASTER: INIT : Temporary directory : %@", NSTemporaryDirectory());
        TSPlasterTemporaryDirectory = [[NSString stringWithFormat:@"%@plaster", NSTemporaryDirectory()] retain];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:TSPlasterTemporaryDirectory]) {
            DLog(@"PLASTER: INIT : Creating temporary Plaster folder at path : [%@]", TSPlasterTemporaryDirectory);
            [fileManager createDirectoryAtPath:TSPlasterTemporaryDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        _operationQueue = [[NSOperationQueue alloc] init];
        
    }
    
    return self;
}

- (void)bootWithPeers:(NSUInteger)maxPeers {
    NSUInteger result = EXIT_FAILURE;
    DLog(@"PLASTER: BOOT : Booting plaster with client ID : [%@], and session ID [%@]", self.clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", self.clientID, self.alias];
    
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
        [_provider subscribeToChannel:self.clientID
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
    BOOL isCopyEnabled = [[self.sessionProfile objectForKey:TSPlasterAllowCMDC] boolValue];
    if (isCopyEnabled) {
        DLog(@"PLASTER: START : Starting pasteboard monitoring every 100ms");
        [self scheduleMonitorWithID:self.clientID andTimeInterval:0.100];
        DLog(@"PLASTER: START : Done.");
    } else {
        DLog(@"PLASTER : START : Starting Plaster in non-copy mode - use Services to Plaster.");
    }
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
    [self invalidateMonitorWithID:self.clientID];
        
    DLog(@"PLASTER: STOP : Stopping plaster session with client ID : [%@], and session ID [%@]", self.clientID, self.sessionKey);
    NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", self.clientID, self.alias];
    
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
    
    BOOL isPeerPaste = [_pb canReadItemWithDataConformingToTypes:@[PLASTER_STRING_UTI, PLASTER_IMAGE_UTI, PLASTER_FILE_UTI]];
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
        if ([pboard availableTypeFromArray:@[NSFilenamesPboardType]]) {
            NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
            DLog(@"PLASTER: PLASTER OUT : File URLS can be obtained from pasteboard : %@", fileNames);
            // Check the file size to verify it is under the limit.
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileNames[0] error:nil];
            if (fileAttributes) {
                DLog(@"PLASTER : PLASTER OUT : FILE : Verifying size...");
                if ([fileAttributes fileSize] > (100 * MB)) {
                    DLog(@"PLASTER: PLASTER OUT : Will not transmit files of length greater than 500MB.");
                    return;
                }
            }
            NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:fileNames[0]];
            if (handle) {
                NSData *contents = [handle readDataToEndOfFile];
                [handle closeFile];
                handle = nil;
                if (contents) {
                    unsigned long length = ceil(([contents length] / MB));
                    DLog(@"PLASTER : PLASTER OUT : Read file contents with length : %luMB", length);
                    const char *jsonBytes = NULL;
                    jsonBytes = [TSPacketSerializer JSONWithDataPacket:contents sender:self.alias];
                    if (jsonBytes == NULL) {
                        DLog(@"PLASTER: PLASTER OUT : Unable to complete operation, no data.");
                        return;
                    }
                    NSString *fileTransferID = [TSClientIdentifier createUUID];
                    NSString *fileTransferKey = [NSString stringWithFormat:TSPlasterSessionFileTransferKey, self.sessionKey, fileTransferID];
                    DLog(@"PLASTER: PLASTER OUT : Setting key for file transfer : %@", fileTransferKey);
                    //[_provider setByteValue:jsonBytes forKey:fileTransferKey];
                    NSMutableDictionary *options = [[NSMutableDictionary alloc]
                                                    initWithDictionary:[_handlerTable objectForKey:@"handlePlasterNotificationForFileWithOptions:"]];
                    NSMutableDictionary *fileTransferOptions = [[NSMutableDictionary alloc] init];
                    [fileTransferOptions setObject:fileTransferID forKey:@"file-transfer-id"];
                    [fileTransferOptions setObject:fileTransferKey forKey:@"file-transfer-key"];
                    [fileTransferOptions setObject:fileNames[0] forKey:@"file-name"];
                    [fileTransferOptions setObject:[NSNumber numberWithLongLong:length] forKey:@"file-size"];
                    [options setObject:fileTransferOptions forKey:@"set-options"];
                    [_handlerTable setObject:options forKey:@"handlePlasterNotificationForFileWithOptions:"];
                    [fileTransferOptions release];
                    
                    [_provider setByteValue:jsonBytes forKey:fileTransferKey
                                withOptions:[self handlerOptionsForHandler:@"handlePlasterNotificationForFileWithOptions:"]];
                    DLog(@"PLASTER: PLASTER OUT : Started file transfer.");
                    [options release];
                    
                    // Set a 600 second expirey for this key
                    /*
                    [_provider setExpiry:TSPlasterRedisKeyExpiry forKey:fileTransferKey];
                    DLog(@"PLASTER: PLASTER OUT : File transmission started asynchronously, and is in progress.");
                    */
                    
                    // We prepare a notification of type content_identifier#length and broadcast this to all peers
                    // This will allow the peers to decide whether they want to fetch the content
                    // The content key will expire in 10 minutes
                    /*
                    NSString *plasterNotification = [NSString stringWithFormat:TSPlasterSessionFileNotificationPattern, fileTransferID,
                                                     [fileNames[0] lastPathComponent], length];
                    DLog(@"PLASTER: PLASTER OUT : Notifying peers with notification string : %@", plasterNotification);
                    const char *notification = [TSPacketSerializer JSONWithNotificationPacket:plasterNotification sender:self.alias];
                    [self transmitJSON:notification];
                    */
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
        
        [_provider publish:json channel:self.clientID
                   options:[self handlerOptionsForHandler:@"handlePlasterNotificationForDataWithSize:"]];
        [options release];
    } else {
        [_provider publish:json channel:self.clientID options:nil];
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
    DLog(@"PLASTER: HANDLE IN : Starting log.");
    NSDictionary *payload = nil;
    if (data) {
        payload = [TSPacketSerializer dictionaryFromJSON:data];
        if (payload) {
            //[payload retain];
            BOOL allowFileType = [[_sessionProfile objectForKey:TSPlasterAllowFiles] boolValue];
            BOOL allowTextType = [[_sessionProfile objectForKey:TSPlasterAllowText] boolValue];
            BOOL allowImageType = [[_sessionProfile objectForKey:TSPlasterAllowImages] boolValue];
            
            NSString *type = [payload objectForKey:TSPlasterJSONKeyForPlasterType];
            id packet = nil;
            
            if ([type isEqualToString:TSPlasterTypeText]) {
                if (!allowTextType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming text-type plasters.");
                } else {
                    DLog(@"PLASTER: HANDLE IN : Processing text packet...");
                    packet = [[TSPlasterString alloc] initWithString:[payload objectForKey:TSPlasterPacketText]];
                }
            } else if ([type isEqualToString:TSPlasterTypeImage]) {
                if (!allowImageType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming image-type plasters.");
                } else {
                    DLog(@"PLASTER: HANDLE IN : Processing image packet...");
                    packet = [[TSPlasterImage alloc] initWithImage:[payload objectForKey:TSPlasterPacketImage]];
                }
            } else if ([type isEqualToString:TSPlasterTypeNotification]) {
                if (!allowFileType) {
                    DLog(@"PLASTER: HANDLE IN : This session does not support incoming file-type plasters.");
                } else {
                    // Peek at the notification and extract the file retrieval key
                    DLog(@"PLASTER: HANDLE IN : Processing notification packet...");
                    packet = [[TSPlasterString alloc] initWithString:[payload objectForKey:TSPlasterPacketText]];
                }
            }
            
            if (!packet) {
                DLog(@"PLASTER: HANDLE IN : Unable to initialize text or image packet.");
                //[payload release];
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
                    //[payload release];
                    [packet release];
                    return;
                }
                DLog(@"PLASTER: HANDLE IN : Pasting...");
                // If the incoming packet is a notification, obtain the file referred to
                // and save it locally. Add a file URL to the pasteboard (will it work!?)
                if ([type isEqualToString:TSPlasterTypeNotification]) {
                    // TODO : Save the file to a temp directory and paste the file URLs
                    NSString *storedPath = [self handleFileNotificationPacket:packet path:nil];
                    DLog(@"PLASTER: HANDLE IN : File notification handled, file stored at : %@", storedPath);
                    //[payload  release];
                    [packet release];
                    packet = [[TSPlasterFile alloc] initWithURL:[NSURL fileURLWithPath:storedPath]];
                }
                
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
                if ([type isEqualToString:TSPlasterTypeNotification]) {
                    // If we recieve a file notification when in file mode,
                    // we just retrieve the file and save it in the plaster folder
                    // rather than the pasteboard
                    [self handleFileNotificationPacket:packet path:[_sessionProfile objectForKey:TSPlasterFolderPath]];
                    DLog(@"PLASTER: HANDLE IN : File notification handled.");
                    BOOL notify = [[_sessionProfile objectForKey:TSPlasterNotifyPlasters] boolValue];
                    if (notify) {
                        NSString *pasteInfo = [NSString stringWithFormat:@"[%@]", sender];
                        [self sendNotificationWithSubtitle:@"You have recieved a new file from :" informativeText:pasteInfo];
                    }
                    //[payload release];
                    [packet release];
                    return;                    
                }
                
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
                    //[payload release];
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
            //[payload release];
            return;
        }
    }
    
    DLog(@"PLASTER: HANDLE IN : Data(%s) or payload(%@) was null. ", data, payload);
    return;
}

- (NSString *)handleFileNotificationPacket:(TSPlasterString *)packet path:(NSString *)aPath {
    [packet retain];
    NSString *filePath = nil;
    if ([packet hasPrefix:@"FILE:"]) {
        NSString *idAndLength = [packet substringFromIndex:5];
        DLog(@"PLASTER: HANDLE IN : Handling notification with id and length : %@", idAndLength);
        NSArray *tokens = [idAndLength componentsSeparatedByString:@"#"];
        NSString *fileTransferID = tokens[0];
        NSString *fileName = tokens[1];
        NSString *fileSize = tokens[2];
        NSInteger len = [fileSize integerValue];
        if (len > 100) {
            DLog(@"PLASTER: HANDLE IN : File length exceeds allowed limit, not retrieving.");
            [packet release];
            return nil;
        }
        NSString *fileTransferKey = [NSString stringWithFormat:TSPlasterSessionFileTransferKey, self.sessionKey, fileTransferID];
        DLog(@"PLASTER: HANDLE IN : Retrieving file with key : %@", fileTransferKey);
        NSString *JSONFileContainerString = [_provider stringValueForKey:fileTransferKey];
        DLog(@"PLASTER: HANDLE IN : Obtained JSON file container of length : %ld", [JSONFileContainerString length]);
        NSDictionary *filePayload = [TSPacketSerializer dictionaryFromJSON:[JSONFileContainerString UTF8String]];
        if (filePayload) {
            NSData *file = [filePayload objectForKey:TSPlasterPacketFile];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            filePath = (aPath != nil) ? [aPath stringByAppendingPathComponent:fileName] :
                                                        [NSString stringWithFormat:@"%@/%@", TSPlasterTemporaryDirectory, fileName];
            DLog(@"PLASTER: HANDLE IN : Writing retrieved file to path : %@", filePath);
            if (![fileManager createFileAtPath:filePath contents:file attributes:nil]) {
                
                DLog(@"PLASTER: HANDLE IN : Unable to create file at path : %@", filePath);
            }
        }
    }
    [packet release];
    return filePath;
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
    NSString *pasteInfo = [NSString stringWithFormat:@"Size [%@]", size];
    [self sendNotificationWithSubtitle:@"Packet has been sent : " informativeText:pasteInfo];
    
    return;
}

- (void)handlePlasterNotificationForFileWithOptions:(NSDictionary *)options {
    // Now send notification to peers to retrieve file.
    // We prepare a notification of type content_identifier#name#length and broadcast this to all peers
    // This will allow the peers to decide whether they want to fetch the content
    // The content key will expire in 10 minutes
    // Set a 600 second expirey for this key
    NSString *fileTransferKey = [options objectForKey:@"file-transfer-key"];
    NSString *fileTransferID = [options objectForKey:@"file-transfer-id"];
    NSString *fileName = [options objectForKey:@"file-name"];
    NSNumber *fileSize = [options objectForKey:@"file-size"];
    
    [_operationQueue addOperationWithBlock:^(void) {
        [_provider setExpiry:TSPlasterRedisKeyExpiry forKey:fileTransferKey];
        DLog(@"PLASTER: PLASTER OUT : File transmission started asynchronously, and is in progress.");
        
        NSString *plasterNotification = [NSString stringWithFormat:TSPlasterSessionFileNotificationPattern, fileTransferID,
                                         [fileName lastPathComponent], [fileSize longValue]];
        DLog(@"PLASTER: PLASTER OUT : Notifying peers with notification string : %@", plasterNotification);
        const char *notification = [TSPacketSerializer JSONWithNotificationPacket:plasterNotification sender:self.alias];
        [self transmitJSON:notification];
        
        DLog(@"Plaster: HANDLE FILE NOTIFICATION : For size : %@MB", fileSize);
        NSString *pasteInfo = [NSString stringWithFormat:@"Size [%@MB]", fileSize];
        [self sendNotificationWithSubtitle:@"File has been sent : " informativeText:pasteInfo];
    }];
    
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
    //NSString *clientIdentifier = [NSString stringWithFormat:@"%@_%@", self.clientID, self.alias];
    for (NSString *sessionKey in sessions) {
        NSString *peersKey = [NSString stringWithFormat:SESSION_PEERS_KEY, sessionKey];
        NSString *peers = [_provider stringValueForKey:peersKey];
        if (!peers) {
            DLog(@"PLASTER: DISCONNECT FROM SESSIONS : No live session found with key : %@", peersKey);
            continue;
        }
        DLog(@"PLASTER: DISCONNECT FROM SESSIONS : Found peers : [%@]", peers);
        NSMutableArray *peerList = [NSMutableArray arrayWithArray:[peers componentsSeparatedByString:@":"]];
        NSMutableIndexSet *removeables = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < [peerList count]; i++) {
            if (!([peerList[i] rangeOfString:self.alias].location == NSNotFound)) {
                [removeables addIndex:i];
            }
        }
        [peerList removeObjectsAtIndexes:removeables];
        //[peerList removeObject:clientIdentifier];
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
    [_sessionKey release];
    [_sessionProfile release];
    [_alias release];
    [TSPlasterTemporaryDirectory release];
    
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
