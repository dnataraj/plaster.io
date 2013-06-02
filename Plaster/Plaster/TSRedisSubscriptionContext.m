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

- (id)initWithRedisContext:(redisAsyncContext *)redisContext channels:(NSArray *)channels bundle:(HandlerBundle)bundle {
    self = [super init];
    if (self) {
        _subscriptionContext = redisContext;
        _channels = channels;
        _bundle = bundle;
    }
    return self;
}

- (redisAsyncContext *)context {
    return _subscriptionContext;
}

- (void)freeBundle {
    if (_bundle) {
        DLog(@"Freeing associated bundle...");
        if (_bundle->data) {
            free(_bundle->data);
        }
        free(_bundle);
    }
}


@end
