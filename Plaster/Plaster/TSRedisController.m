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
#import "errno.h"

void _signal(const char *caller, void *bundle) {
    if (bundle) {
        HandlerBundle hb = (HandlerBundle)bundle;
        if (hb->semaphore) {
            NSLog(@"REDIS : %s : Signalling...", caller);
            dispatch_semaphore_signal(*hb->semaphore);
        }
    }
}

BOOL rcProcessReply(redisAsyncContext *ctx, void *r, void *data) {
    redisReply *reply = r;
    if (reply == NULL) {
        NSLog(@"REDIS : The reply was null, checking context...");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    NSLog(@"REDIS : Error occured : %s", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    NSLog(@"REDIS :  The server closed the connection which resulted in an empty read. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    NSLog(@"REDIS :  There was an error while parsing the protocol. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    NSLog(@"REDIS :  Possible error when resolving hostname. : %s", ctx->errstr);
                    break;
                    
                default:
                    NSLog(@"REDIS : Unknown error. : %s", ctx->errstr);
                    break;
            }
        } else {
            NSLog(@"Context is null as well. Aborting.");
        }
        return NO;
    }
    
    switch (reply->type) {
        case REDIS_REPLY_STATUS:
            NSLog(@"REDIS : REDIS_REPLY_STATUS : %s", reply->str);
            break;
        case REDIS_REPLY_ERROR:
            NSLog(@"REDIS : ERROR! :REDIS_REPLY_ERROR : %s", reply->str);
            break;
        case REDIS_REPLY_INTEGER:
            NSLog(@"REDIS : REDIS_REPLY_INTEGER : %lld", reply->integer);
            break;
        case REDIS_REPLY_NIL:
            NSLog(@"REDIS : REDIS_REPLY_NIL : no data.");
            break;
        case REDIS_REPLY_STRING:
            NSLog(@"REDIS : REDIS_REPLY_STRING : %s", reply->str);
            break;
        case REDIS_REPLY_ARRAY:
            NSLog(@"REDIS : REDIS_REPLY_ARRAY : Number of elements : %zd", reply->elements);
            break;
            
        default:
            break;
    }
    
    return YES;
}

void rcSet(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_STATUS) {
            if (strcmp(reply->str, "OK")) {
                NSLog(@"REDIS : SET replied with OK.");
                if (data) {
                    HandlerBundle hb = (HandlerBundle)data;
                    hb->int_data = 1;
                }
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            NSLog(@"REDIS : SET replied with (nil).");
            if (data) {
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = 0;
            }
            
        }
        NSLog(@"REDIS : SET : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    _signal("SET", data);
    return;
}

void rcGet(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_STRING) {
            if (data) {
                NSLog(@"REDIS : Processing GET reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->data = (char *)malloc(strlen(reply->str));
                strcpy(hb->data, reply->str);
            }
        }
        
        NSLog(@"REDIS : GET : Disconnecting...");
        redisAsyncDisconnect(ctx);        
    }
    
    _signal("GET", data);
    return;
}

void rcIncr(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                NSLog(@"REDIS : Processing INCR reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        NSLog(@"REDIS : INCR : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    
    _signal("INCR", data);
    return;
}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;
    }
    printf("REDIS : Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        NSLog(@"Error: %s\n", c->errstr);
        return;
    }
    NSLog(@"REDIS : Disconnected.");
}

void subscribe(redisAsyncContext *c, void *r, void *data) {
    redisReply *reply = r;
    if (reply == NULL) {
        return;
    }
    if (reply->type == REDIS_REPLY_ARRAY) {
        for (int j = 0; j < reply->elements; j++) {
            printf("%u) %s\n", j, reply->element[j]->str);
        }
    }
    if (reply->elements > 2) {
        HandlerBundle hb = (HandlerBundle)data;
        NSLog(@"Invoking callback handler...");
        (hb->handler)(reply->element[2]->str, hb->data);
    }
}

HandlerBundle makeHandlerBundle(mpCallback callback, void *data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = data;
    if (callback) {
        hb->handler = (__bridge void *) callback;
    }
    hb->semaphore = sema;
    return hb;
}

HandlerBundle makeHandlerBundleObjC(mpCallback callback, id data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = (__bridge void *)(data);
    if (callback) {
        hb->handler = (__bridge void *) callback;
    }
    hb->semaphore = sema;
    return hb;
}

void freeBundle(HandlerBundle hb) {
    free(hb->data);
    //dispatch_release(*hb->semaphore);
    hb->semaphore = nil;
    free(hb);
}

@implementation TSRedisController {
    redisAsyncContext *_asyncPubSessionContext;
    redisAsyncContext *_asyncSubSessionContext;
    TSEventDispatcher *_dispatcher;
}

- (id)initWithIPAddress:(NSString *)ip andPort:(NSUInteger)port {
    self = [super init];
    if (self) {
        signal(SIGPIPE, SIG_IGN);
        _redisHost = [NSHost hostWithAddress:ip];
        _redisPort = port;
        
        _dispatcher = [[TSEventDispatcher alloc] init];
        if (_dispatcher) {
            // Setting up the asynchronous publish context
            
            _asyncPubSessionContext = [self connect];
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
            
            int result = [_dispatcher dispatchWithContext:_asyncPubSessionContext];
            if (result == REDIS_OK) {
                NSLog(@"Setting pub async connect callback...");
                redisAsyncSetConnectCallback(_asyncPubSessionContext, connectCallback);
                NSLog(@"Setting pub async disconnect callback...");
                redisAsyncSetDisconnectCallback(_asyncPubSessionContext, disconnectCallback);
            } else {
                NSLog(@"Dispatching pub failed with code : %d", result);
            }
     
            result = [_dispatcher dispatchWithContext:_asyncSubSessionContext];
            if (result == REDIS_OK) {
                NSLog(@"Setting sub async connect callback...");
                redisAsyncSetConnectCallback(_asyncSubSessionContext, connectCallback);
                NSLog(@"Setting sub async disconnect callback...");
                redisAsyncSetDisconnectCallback(_asyncSubSessionContext, disconnectCallback);
            } else {
                NSLog(@"Dispatching sub failed with code : %d", result);
            }
            
        } else {
            NSLog(@"Unable to initialize event dispatcher, exiting Redis controller...");
            return nil;
        }
        
    }

    return self;
}

- (id)init {
    return [self initWithIPAddress:@REDIS_IP andPort:REDIS_PORT];
}

- (redisAsyncContext *)connect {
    return redisAsyncConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
}

- (redisAsyncContext *)connectAndDispatch {
    redisAsyncContext *localAsyncCtx = redisAsyncConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
    if (localAsyncCtx->err) {
        ALog(@"REDIS : Error establishing connection : %s\n", localAsyncCtx->errstr);
        return NULL;
    } else {
        DLog(@"REDIS : Established connection to %@\n", [[self redisHost] address]);
    }
    DLog(@"REDIS : Dispatching context...");
    uint result = [_dispatcher dispatchWithContext:localAsyncCtx];
    if (result != REDIS_OK) {
        ALog(@"REDIS : Error dispatching Redis context to event loop : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    DLog(@"REDIS : Setting disconnect callback...");
    result = redisAsyncSetDisconnectCallback(localAsyncCtx, disconnectCallback);
    if (result != REDIS_OK) {
        ALog(@"REDIS : Error setting disconnect callback : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    
    return localAsyncCtx;
}

- (void)subscribeToChannels:(NSArray *)channels withCallback:(mpCallback)callback andContext:(id)context {
    NSMutableString *subCmd = [[NSMutableString alloc] initWithFormat:@"SUBSCRIBE %@", [channels componentsJoinedByString:@" "]];
    NSLog(@"REDIS : Subscription command [%@]", subCmd);
    HandlerBundle subscriptionBundle = makeHandlerBundle(callback, (__bridge void *)context, nil);
    redisAsyncCommand(_asyncSubSessionContext, subscribe, subscriptionBundle, [subCmd UTF8String]);
}

- (void)publishObject:(NSString *)object toChannel:(NSString *)channel {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ '%%b'", channel];
    NSLog(@"REDIS : Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, [pubCmd UTF8String], [object UTF8String], strlen([object UTF8String]));
}

- (void)publish:(const char *)bytes toChannel:(NSString *)channel {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ '%%b'", channel];
    NSLog(@"REDIS : Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, [pubCmd UTF8String], bytes, strlen(bytes));
}

- (void)unsubscribe {
    NSLog(@"REDIS : Unsubscribing from all channels...");
    redisAsyncCommand(_asyncSubSessionContext, NULL, NULL, "UNSUBSCRIBE");
}

-(void)setStringValue:(NSString *)stringValue forKey:(NSString *)key {
    DLog(@"REDIS : Setting value [%@] for key [%@]...", stringValue, key);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    HandlerBundle bundle = NULL;
    if (localAsyncCtx) {
        dispatch_semaphore_t set = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &set);
        uint result = redisAsyncCommand(localAsyncCtx, rcSet, bundle, "SET %s %b", [key UTF8String], [stringValue UTF8String],
                                                                                 strlen([stringValue UTF8String]));
        if (result != REDIS_OK) {
            ALog(@"REDIS : Error buffering SET command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            return;
        }
        dispatch_semaphore_wait(set, DISPATCH_TIME_FOREVER);
    } else {
        NSLog(@"REDIS : Unable to complete SET.");
    }

    freeBundle(bundle);
    return;
}

-(BOOL)setNXStringValue:(NSString *)stringValue forKey:(NSString *)key {
    DLog(@"REDIS : NX : Setting value [%@] for key [%@]...", stringValue, key);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    BOOL isSet = NO;
    HandlerBundle bundle = NULL;
    if (localAsyncCtx) {
        dispatch_semaphore_t setnx = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &setnx);
        uint result = redisAsyncCommand(localAsyncCtx, rcSet, bundle, "SET %s %b NX", [key UTF8String], [stringValue UTF8String],
                                                                                        strlen([stringValue UTF8String]));
        if (result != REDIS_OK) {
            ALog(@"REDIS : Error buffering SETNX command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            return NO;
        }
        dispatch_semaphore_wait(setnx, DISPATCH_TIME_FOREVER);
        if (bundle) {
            if (bundle->int_data) {
                DLog(@"REDIS : NX : Key was set.");
                isSet = YES;
            }
        }
    } else {
        NSLog(@"REDIS : Unable to complete SETNX.");
    }
    
    freeBundle(bundle);
    return isSet;
}

-(NSString *)stringValueForKey:(NSString *)key {
    DLog(@"REDIS : Getting value for key [%@]...", key);
    NSString *stringValue = nil;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t get = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &get);
        uint result = redisAsyncCommand(localAsyncCtx, rcGet, bundle, "GET %s", [key UTF8String]);
        if (result != REDIS_OK) {
            ALog(@"REDIS : Error buffering GET command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            return nil;
        }
        dispatch_semaphore_wait(get, DISPATCH_TIME_FOREVER);
        if (bundle->data) {
            stringValue = [NSString stringWithCString:((char *)bundle->data) encoding:NSUTF8StringEncoding];
            //DLog(@"REDIS : Obtained value from GET %@", stringValue);
        }
    } else {
        DLog(@"REDIS : Unable to complete GET.");
    }
    
    free(bundle->data);
    free(bundle); // IMP!
    
    return stringValue;
}

-(NSUInteger)incrementKey:(NSString *)key {
    DLog(@"REDIS : Incrementing key [%@]...", key);
    NSUInteger incremented = UINT32_MAX;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t incr = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &incr);
        uint result = redisAsyncCommand(localAsyncCtx, rcIncr, bundle, "INCR %s", [key UTF8String]);
        if (result != REDIS_OK) {
            ALog(@"REDIS : Error buffering INCR command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            return incremented;
        }
        dispatch_semaphore_wait(incr, DISPATCH_TIME_FOREVER);
        if (bundle) {
            incremented = bundle->int_data;
        }
    } else {
        DLog(@"REDIS : Unable to complete INCR.");
    }
    
    free(bundle); // IMP!
    return incremented;
}

/*
-(void)setDictionaryValue:(NSDictionary *)dictionary forKey:(NSString *)key;
-(NSDictionary *)dictionaryValueForKey:(NSString *)key;
-(NSArray *)dictionaryKeysForKey:(NSString *)key;
*/

- (void)terminate {
    NSLog(@"Unsubscribe from any open channels and disconnect from Redis...");
    
    if (!_asyncPubSessionContext->err) {
        redisAsyncDisconnect(_asyncPubSessionContext);        
    }
    if (!_asyncSubSessionContext->err) {
        [self unsubscribe];
        redisAsyncDisconnect(_asyncSubSessionContext);        
    }
    

}

@end
