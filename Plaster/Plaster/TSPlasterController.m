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

@interface TSPlasterController ()

@property (readwrite, atomic) BOOL isMonitoring;

@end

@implementation TSPlasterController {
    NSPasteboard *_pb;
    NSInteger _changeCount;
    NSArray *_readables;
    
    TSEventDispatcher *_dispatcher;
    void (^plaster)(void);
    
    id <TSMessagingProvider, TSDataStoreProvider> _provider;
}

void (^publishCallback)(id) = ^(id context) {
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

        plaster = ^(void) {
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
            [_provider publish:jsonBytes toChannel:@"device3" withCallback:publishCallback];
        };
        
    }
    
    return self;
}

- (void)scheduleMonitorWithID:(NSString *)id andTimeInterval:(NSTimeInterval)interval {
    uint ret = [_dispatcher dispatchTask:id WithPeriod:(interval * NSEC_PER_SEC) andHandler:plaster];
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
