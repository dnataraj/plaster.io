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
#import "TSDataStoreProvider.h"

@class TSEventDispatcher;

typedef void (*tsSubcriptionHandler)(redisAsyncContext *c, void *reply, void *privateData);
typedef void (*tsPublishHandler)(redisAsyncContext *c, void *reply, void *privateData);

typedef struct {
    long long int_data;
    void *data;
    void (*handler)(char *reply, void *);
    const __unsafe_unretained dispatch_semaphore_t *semaphore;
} *HandlerBundle;

HandlerBundle makeHandlerBundleObjC(mpCallback callback, id data, dispatch_semaphore_t *sema);
HandlerBundle makeHandlerBundle(mpCallback callback, void *data, dispatch_semaphore_t *sema);

@interface TSRedisController : NSObject <TSMessagingProvider, TSDataStoreProvider>

@property (readwrite, retain) NSHost *redisHost;
@property (readwrite, assign) NSUInteger redisPort;

- (id)initWithIPAddress:(NSString *)ip andPort:(NSUInteger)port;
- (void)unsubscribe;
- (void)terminate;

@end
