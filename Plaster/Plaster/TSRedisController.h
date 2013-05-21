//
//  TSRedisController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/15/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "async.h"

@class TSEventDispatcher;

typedef void (*tsSubcriptionHandler)(redisAsyncContext *c, void *reply, void *privateData);
typedef void (*tsPublishHandler)(redisAsyncContext *c, void *reply, void *privateData);

@interface TSRedisController : NSObject

- (id)initWithDispatcher:(TSEventDispatcher *)dispatcher;
- (void)subscribeToChannels:(NSArray *)channels withHandler:(tsSubcriptionHandler)handler andContext:(void *)context;
- (void)publishMessage:(NSString *)message toChannel:(NSString *)channel withHandler:(tsPublishHandler)handler;
- (void)unsubscribe;
- (void)terminate;

@end
