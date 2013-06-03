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

- (id)initWithPasteboard:(NSPasteboard *)pasteboard provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider;

- (void)onTimer;
- (void)start;
- (void)stop;

@end
