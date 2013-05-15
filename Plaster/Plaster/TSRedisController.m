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
#import "adapters/libevent.h"
#import "TSPlasterGlobals.h"


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
    struct event_base *_base;
}

- (id)init {
    self = [super init];
    if (self) {
        _base = event_base_new();
        _asyncSessionContext = redisAsyncConnect(LOCAL_IP, REDIS_PORT);
        if (_asyncSessionContext->err) {
            NSLog(@"Error establishing connection : %s\n", _asyncSessionContext->errstr);
        } else {
            NSLog(@"Established connection to %@\n", @LOCAL_IP);
        }
        NSLog(@"Attaching to libevent base...");
        redisLibeventAttach(_asyncSessionContext, _base);
        NSLog(@"Setting async connect callback...");
        redisAsyncSetConnectCallback(_asyncSessionContext, connectCallback);
        NSLog(@"Setting async disconnect callback...");
        redisAsyncSetDisconnectCallback(_asyncSessionContext, disconnectCallback);

        /*
        int redisvAsyncCommand(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, const char *format, va_list ap);
        int redisAsyncCommand(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, const char *format, ...);
        int redisAsyncCommandArgv(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, int argc, const char **argv, const size_t *argvlen);
        */
        
        const char *value = "foo";
        redisAsyncCommand(_asyncSessionContext, NULL, NULL, "SET key %b", value, strlen(value));
        redisAsyncCommand(_asyncSessionContext, getCallback, (char*)"end-1", "GET key");
        event_base_dispatch(_base);
    }
    
    return self;
}



@end
