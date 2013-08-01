//
//  TSPasteboardController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessagingProvider.h"
#import "TSDataStoreProvider.h"

@interface TSLPlasterController : NSObject

@property (copy) NSString *sessionKey;
@property (copy) NSString *clientID;
@property (copy) NSDictionary *sessionProfile;
@property (nonatomic, copy) NSString *alias;
@property NSInteger changeCount;
@property (atomic, getter = hasStarted) BOOL started;
@property (atomic, getter = isRunning) BOOL running;

- (id)initWithPasteboard:(UIPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider;

- (void)onTimer;
- (void)onTimerWithNotification:(NSNotification *)notification;
- (void)start;
- (void)stop;
- (NSArray *)connectedPeers;

- (void)disconnectFromSessions:(NSArray *)sessions;
- (void)plaster:(UIPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

@end
