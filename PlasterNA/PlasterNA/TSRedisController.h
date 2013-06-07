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

typedef struct _handlerbundle {
    long long int_data;
    void *data;
    mpCallback handler;
} *HandlerBundle;

HandlerBundle makeHandlerBundle(mpCallback callback, void *data);

@interface TSRedisController : NSObject <TSMessagingProvider, TSDataStoreProvider>

@property (readwrite, retain) NSHost *redisHost;
@property (readwrite) NSUInteger redisPort;
@property (readwrite, atomic) NSUInteger numSubscribers;

- (id)initWithIPAddress:(NSString *)ip port:(NSUInteger)port;

@end
