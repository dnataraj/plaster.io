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

@interface TSPlasterController : NSObject <NSUserNotificationCenterDelegate>

@property (readwrite, atomic, copy) NSString *sessionKey;
@property (copy) NSDictionary *sessionProfile;
@property (readwrite, nonatomic, copy) NSString *alias;
@property NSInteger changeCount;
@property BOOL started, running;

- (id)initWithPasteboard:(NSPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider;

- (void)onTimer;
- (void)start;
- (void)stop;
- (NSArray *)connectedPeers;

- (void)disconnectFromSessions:(NSArray *)sessions;
- (void)plaster:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

@end
