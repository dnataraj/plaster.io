//
//  TSRedisController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/15/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "async.h"
#import "TSMessagingProvider.h"

@class TSEventDispatcher;

typedef void (*tsSubcriptionHandler)(redisAsyncContext *c, void *reply, void *privateData);
typedef void (*tsPublishHandler)(redisAsyncContext *c, void *reply, void *privateData);

@interface TSRedisController : NSObject <TSMessagingProvider>

- (void)unsubscribe;
- (void)terminate;

@end
