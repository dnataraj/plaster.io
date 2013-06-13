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

@property (readwrite, atomic, copy) NSString *sessionKey;
@property (readwrite, nonatomic, copy) NSString *alias;

- (id)initWithPasteboard:(NSPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider;

- (void)onTimer;
- (void)start;
- (void)stop;
- (NSArray *)connectedPeers;
- (IBAction)disconnect:(id)sender;

@end
