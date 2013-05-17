//
//  TSRedisController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/15/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSRedisController.h"
#import "hiredis.h"
#import "async.h"
#import "TSPlasterGlobals.h"
#import "TSEventDispatcher.h"


void getCallback(redisAsyncContext *c, void *r, void *privdata) {
    redisReply *reply = r;
    if (reply == NULL) return;
    printf("argv[%s]: %s\n", (char*)privdata, reply->str);
    
    /* Disconnect after receiving the reply to GET */
    redisAsyncDisconnect(c);
}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;
    }
    printf("Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;
    }
    printf("Disconnected...\n");
}

@implementation TSRedisController {
    redisAsyncContext *_asyncSessionContext;
}

- (id)initWithDispatcher:(TSEventDispatcher *)dispatcher {
    self = [super init];
    if (self) {
        if (dispatcher) {
            _asyncSessionContext = redisAsyncConnect(LOCAL_IP, REDIS_PORT);
            if (_asyncSessionContext->err) {
                NSLog(@"Error establishing connection : %s\n", _asyncSessionContext->errstr);
            } else {
                NSLog(@"Established connection to %@\n", @LOCAL_IP);
            }
            
            int result = [dispatcher dispatchWithContext:_asyncSessionContext];
            if (result == REDIS_OK) {
                NSLog(@"Setting async connect callback...");
                redisAsyncSetConnectCallback(_asyncSessionContext, connectCallback);
                NSLog(@"Setting async disconnect callback...");
                redisAsyncSetDisconnectCallback(_asyncSessionContext, disconnectCallback);
                NSLog(@"Dispatched...");
            } else {
                NSLog(@"Dispatching failed with code : %d", result);
            }
        }
    }

    return self;
}

- (id)init {
    return [self initWithDispatcher:nil];
}

- (void)subscribeToChannels:(NSArray *)channels withHandler:(tsSubcriptionHandler)handler andContext:(void *)context {
    NSMutableString *subCmd = [[NSMutableString alloc] initWithFormat:@"SUBSCRIBE %@", [channels componentsJoinedByString:@" "]];
    NSLog(@"REDIS : Subscription command [%@]", subCmd);
    redisAsyncCommand(_asyncSessionContext, handler, context, [subCmd UTF8String]);
}


@end
