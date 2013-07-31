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

@class TSLEventDispatcher;

typedef struct _handlerbundle {
    long long int_data;
    void *data;
    mpCallback handler;
} *HandlerBundle;

HandlerBundle makeHandlerBundle(mpCallback callback, void *data);

@interface TSLRedisController : NSObject <TSMessagingProvider, TSDataStoreProvider>

@property (readwrite, copy) NSString *redisHostAddress;
@property (readwrite) NSUInteger redisPort;
@property (readwrite, atomic) NSUInteger numSubscribers;

- (id)initWithIPAddress:(NSString *)ipv4Address port:(NSUInteger)port;

@end
