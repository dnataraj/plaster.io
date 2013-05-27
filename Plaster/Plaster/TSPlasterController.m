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

//#define PEER_JOIN_CHANNEL "plaster:join:"
#define PLASTER_SESSION_KEY "plaster:session:"

@interface TSPlasterController ()

@property (readwrite, atomic) BOOL isMonitoring;

@end

@implementation TSPlasterController {
    NSPasteboard *_pb;
    NSInteger _changeCount;
    NSArray *_readables;
    
    TSEventDispatcher *_dispatcher;
    
    // The block declaration for handling a local pb copy
    void (^plasterOut)(void);
    // The block declaration to handle new peer join's
    void (^handleNewPeer)(id, id);
    // The block declaration to handle incoming plasters from a peer
    void (^plasterIn)(id);
    
    id <TSMessagingProvider, TSDataStoreProvider> _provider;
    //NSString *_clientID;
}

void (^publishCallback)(id, id) = ^(id reply, id context) {
    NSLog(@"Pasting to peers...");
};

- (id)initWithPasteboard:(NSPasteboard *)pasteboard andProvider:(id<TSMessagingProvider, TSDataStoreProvider>)provider {
    self = [super init];
    if (self) {
        if (!pasteboard || !provider) {
            NSLog(@"The pasteboard controller needs both a valid pasteboard and a message provider.");
            return nil;
        }

        _provider = provider;
        _pb = pasteboard;
        _dispatcher = [[TSEventDispatcher alloc] init];
        _changeCount = [_pb changeCount];
        //_readables = [NSArray arrayWithObjects:[TSPasteboardPacket class] ,[NSString class], nil];
        _readables = [NSArray arrayWithObjects:[NSString class], nil];

        plasterOut = ^(void) {
            NSInteger newChangeCount = [_pb changeCount];
            if (_changeCount == newChangeCount) {
                return;
            }
            _changeCount = newChangeCount;
            BOOL isPeerPaste = [_pb canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:@"com.trilobytesystems.plaster.uti"]];
            if (isPeerPaste) {
                NSLog(@"Packet is from a peer, discarding publish..");
                return;
            }
            NSLog(@"Reading the general pasteboard...");
            NSArray *pbContents = [_pb readObjectsForClasses:_readables options:nil];
            NSLog(@"Found in pasteboard : [%@]" , [pbContents objectAtIndex:0]);
            // Now we have to extract the bytes
            id packet = [pbContents objectAtIndex:0];
            NSLog(@"Processing NSString packet and publishing...");
            const char *jsonBytes = [TSPacketSerializer JSONWithStringPacket:[[NSString alloc] initWithString:packet]];
            [_provider publish:jsonBytes toChannel:@"device3"];
        };
        
        handleNewPeer = ^(id reply, id data) {
            NSLog(@"Handling new peers...");
        };
        
    }
    
    return self;
}

- (void)bootWithPeers:(NSUInteger)maxPeers {
    NSString *clientID = [TSClientIdentifier clientID];
    
    // Obtain a session id from the user preferences (Note : this client could the session initiator, or a participant)
    NSString *clientSessionID = [[NSUserDefaults standardUserDefaults] objectForKey:@"plaster-session-id"];
    DLog(@"PLASTER BOOT : Booting plaster with client ID : [%@], and session ID [%@]", clientID, clientSessionID);
    
    // 1. Does a plaster session exist for this key?
    NSString *sessionKey = [NSString stringWithFormat:@"%@%@", @PLASTER_SESSION_KEY, clientSessionID];
    DLog(@"PLASTER BOOT : Verifying session for key : [%@]", sessionKey);
    BOOL sessionExists = [_provider setNXStringValue:@"1" forKey:sessionKey];  // eq: SET key value NX

    if (sessionExists) {
        DLog(@"PLASTER BOOT : Found session with key [%@]", sessionKey);
    } else {
        DLog(@"PLASTER BOOT : New session. This client is participant 1");
    }

}


- (void)scheduleMonitorWithID:(NSString *)id andTimeInterval:(NSTimeInterval)interval {
    uint ret = [_dispatcher dispatchTask:id WithPeriod:(interval * NSEC_PER_SEC) andHandler:plasterOut];
    if (ret == TS_DISPATCH_ERR) {
        NSLog(@"Error starting Plaster monitor : Unable to create/start dispatch timer, id : %@", id);
    }
}

- (void)invalidateMonitorWithID:(NSString *)id {
    uint ret = [_dispatcher stopTask:id];
    if (ret == TS_DISPATCH_ERR) {
        NSLog(@"Error invalidating Plaster monitor : Unable to stop dispatch timer, id : %@", id);
    }
}


@end
