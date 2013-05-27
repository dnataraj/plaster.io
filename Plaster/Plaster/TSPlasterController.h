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

@interface TSPlasterController : NSObject

@property (readwrite, atomic) NSSet *peers;

- (id)initWithPasteboard:(NSPasteboard *)pasteboard andProvider:(id<TSMessagingProvider, TSDataStoreProvider>)publisher;

- (void)bootWithPeers:(NSUInteger)maxPeers;
- (void)scheduleMonitorWithID:(NSString *)id andTimeInterval:(NSTimeInterval)interval;
- (void)invalidateMonitorWithID:(NSString *)id;

@end
