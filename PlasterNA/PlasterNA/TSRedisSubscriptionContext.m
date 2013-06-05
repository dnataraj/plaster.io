//
//  TSAsyncRedisContext.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/28/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSRedisSubscriptionContext.h"

@implementation TSRedisSubscriptionContext {
    redisAsyncContext *_subscriptionContext;
    HandlerBundle _bundle;
}

- (id)initWithRedisContext:(redisAsyncContext *)redisContext channels:(NSString *)someChannels bundle:(HandlerBundle)bundle {
    self = [super init];
    if (self) {
        _subscriptionContext = redisContext;
        _bundle = bundle;
        //NSLog(@"Setting channels to [%@].", someChannels);
        [self setChannels:someChannels];
    }
    return self;
}

- (id)initWithRedisContext:(redisAsyncContext *)redisContext {
    return [self initWithRedisContext:redisContext channels:nil bundle:NULL];
}

- (redisAsyncContext *)context {
    return _subscriptionContext;
}

- (void)freeBundle {
    if (_bundle != NULL) {
        NSLog(@"Freeing associated bundle...");
        if (_bundle->data != NULL) {
            free(_bundle->data);
        }
        free(_bundle);
    }
}

- (void)dealloc {
    _subscriptionContext = nil;
    [_channels release];
    _bundle = nil;
    //[self freeBundle];
    [super dealloc];
}

@end
