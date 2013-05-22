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
    redisAsyncContext *_asyncPubSessionContext;
    redisAsyncContext *_asyncSubSessionContext;
}

- (id)initWithDispatcher:(TSEventDispatcher *)dispatcher {
    self = [super init];
    if (self) {
        if (dispatcher) {
            // Setting up the asynchronous publish context
            _asyncPubSessionContext = redisAsyncConnect(REDIS_IP, REDIS_PORT);
            if (_asyncPubSessionContext->err) {
                NSLog(@"Error establishing connection : %s\n", _asyncPubSessionContext->errstr);
            } else {
                NSLog(@"Established connection to %@\n", @REDIS_IP);
            }
            
            // Setting up the asynchronous subscribe context
            _asyncSubSessionContext = redisAsyncConnect(REDIS_IP, REDIS_PORT);
            if (_asyncSubSessionContext->err) {
                NSLog(@"Error establishing connection : %s\n", _asyncSubSessionContext->errstr);
            } else {
                NSLog(@"Established connection to %@\n", @REDIS_IP);
            }
            
            int result = [dispatcher dispatchWithContext:_asyncPubSessionContext];
            if (result == REDIS_OK) {
                NSLog(@"Setting pub async connect callback...");
                redisAsyncSetConnectCallback(_asyncPubSessionContext, connectCallback);
                NSLog(@"Setting pub async disconnect callback...");
                redisAsyncSetDisconnectCallback(_asyncPubSessionContext, disconnectCallback);
            } else {
                NSLog(@"Dispatching pub failed with code : %d", result);
            }
     
            result = [dispatcher dispatchWithContext:_asyncSubSessionContext];
            if (result == REDIS_OK) {
                NSLog(@"Setting sub async connect callback...");
                redisAsyncSetConnectCallback(_asyncSubSessionContext, connectCallback);
                NSLog(@"Setting sub async disconnect callback...");
                redisAsyncSetDisconnectCallback(_asyncSubSessionContext, disconnectCallback);
            } else {
                NSLog(@"Dispatching sub failed with code : %d", result);
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
    redisAsyncCommand(_asyncSubSessionContext, handler, context, [subCmd UTF8String]);
}

- (void)publishMessageString:(NSString *)message toChannel:(NSString *)channel withHandler:(tsPublishHandler)handler {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ '%%b'", channel];
    NSLog(@"REDIS : Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, handler, NULL, [pubCmd UTF8String], [message UTF8String], strlen([message UTF8String]));
}

- (void)publishMessage:(const char *)message toChannel:(NSString *)channel withHandler:(tsPublishHandler)handler {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ '%%b'", channel];
    NSLog(@"REDIS : Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, handler, NULL, [pubCmd UTF8String], message, strlen(message));
}

- (void)unsubscribe {
    NSLog(@"REDIS : Unsubscribing from all channels...");
    redisAsyncCommand(_asyncSubSessionContext, NULL, NULL, "UNSUBSCRIBE");
}

- (void)terminate {
    NSLog(@"Unsubscribe from any open channels and disconnect from Redis...");
    [self unsubscribe];
    redisAsyncDisconnect(_asyncPubSessionContext);
    //redisFree(&_asyncPubSessionContext->c);
    redisAsyncDisconnect(_asyncSubSessionContext);
    //redisFree(&_asyncSubSessionContext->c);
}

@end
