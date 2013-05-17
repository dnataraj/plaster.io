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

void onMessage(redisAsyncContext *c, void *reply, void *privdata) {
    redisReply *r = reply;
    if (reply == NULL) return;
    
    if (r->type == REDIS_REPLY_ARRAY) {
        for (int j = 0; j < r->elements; j++) {
            printf("%u) %s\n", j, r->element[j]->str);
        }
    }
}

@implementation TSRedisController {
    redisAsyncContext *_asyncSessionContext;
    //TSEventDispatcher *_dispatcher;
}

- (id)initWithDispatcher:(TSEventDispatcher *)dispatcher {
    self = [super init];
    if (self) {
        if (dispatcher) {
            //_dispatcher = dispatcher;
            
            _asyncSessionContext = redisAsyncConnect(LOCAL_IP, REDIS_PORT);
            if (_asyncSessionContext->err) {
                NSLog(@"Error establishing connection : %s\n", _asyncSessionContext->errstr);
            } else {
                NSLog(@"Established connection to %@\n", @LOCAL_IP);
            }
            
            [dispatcher dispatchWithContext:_asyncSessionContext];
            
            NSLog(@"Setting async connect callback...");
            redisAsyncSetConnectCallback(_asyncSessionContext, connectCallback);
            NSLog(@"Setting async disconnect callback...");
            redisAsyncSetDisconnectCallback(_asyncSessionContext, disconnectCallback);
            
            NSLog(@"Subscribing to channel...");
            redisAsyncCommand(_asyncSessionContext, onMessage, NULL, "SUBSCRIBE magic");
            
            NSLog(@"Dispatched...");            
        }
    }

    return self;
}

- (id)init {
    return [self initWithDispatcher:nil];
}


@end
