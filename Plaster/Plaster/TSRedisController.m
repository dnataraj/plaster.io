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
#import "TSClientIdentifier.h"
#import "TSRedisSubscriptionContext.h"
#import "errno.h"

void _signal(const char *caller, void *bundle) {
    if (bundle) {
        HandlerBundle hb = (HandlerBundle)bundle;
        if (hb->semaphore) {
            //NSLog(@"REDIS: %s : Signalling...", caller);
            printf("REDIS: %s : Signalling...", caller);
            dispatch_semaphore_signal(*(hb->semaphore));
        }
    }
}

BOOL rcProcessReply(redisAsyncContext *ctx, void *r, void *data) {
    redisReply *reply = r;
    if (reply == NULL) {
        NSLog(@"REDIS: The reply was null, checking context...");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    NSLog(@"REDIS: Error occured : %s", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    NSLog(@"REDIS:  The server closed the connection which resulted in an empty read. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    NSLog(@"REDIS:  There was an error while parsing the protocol. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    NSLog(@"REDIS:  Possible error when resolving hostname. : %s", ctx->errstr);
                    break;
                    
                default:
                    NSLog(@"REDIS: Unknown error. : %s", ctx->errstr);
                    break;
            }
        } else {
            NSLog(@"Context is null as well. Aborting.");
        }
        return NO;
    }
    
    switch (reply->type) {
        case REDIS_REPLY_STATUS:
            NSLog(@"REDIS: REDIS_REPLY_STATUS : %s", reply->str);
            break;
        case REDIS_REPLY_ERROR:
            NSLog(@"REDIS: ERROR! :REDIS_REPLY_ERROR : %s", reply->str);
            break;
        case REDIS_REPLY_INTEGER:
            NSLog(@"REDIS: REDIS_REPLY_INTEGER : %lld", reply->integer);
            break;
        case REDIS_REPLY_NIL:
            NSLog(@"REDIS: REDIS_REPLY_NIL : no data.");
            break;
        case REDIS_REPLY_STRING:
            NSLog(@"REDIS: REDIS_REPLY_STRING : %s", reply->str);
            break;
        case REDIS_REPLY_ARRAY:
            NSLog(@"REDIS: REDIS_REPLY_ARRAY : Number of elements : %zd", reply->elements);
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
                NSLog(@"REDIS: SET replied with OK.");
                if (data) {
                    HandlerBundle hb = (HandlerBundle)data;
                    hb->int_data = 1;
                }
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            NSLog(@"REDIS: SET replied with (nil).");
            if (data) {
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = 0;
            }
            
        }
        NSLog(@"REDIS: SET : Disconnecting...");
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
                NSLog(@"REDIS: GET : Processing GET reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->data = (char *)malloc(strlen(reply->str));
                strcpy(hb->data, reply->str);
            }
        }
        
        NSLog(@"REDIS: GET : Disconnecting...");
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
                NSLog(@"REDIS: INCR : Processing INCR reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        NSLog(@"REDIS: INCR : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    
    _signal("INCR", data);
    return;
}

void rcDel(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                NSLog(@"REDIS: DEL : Processing DEL reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        NSLog(@"REDIS: DEL : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    
    _signal("DEL", data);
    return;
}

void rcSubscribe(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_ARRAY) {
            for (int j = 0; j < reply->elements; j++) {
                printf("%u) %s\n", j, reply->element[j]->str);
            }
            if (reply->elements > 2) {
                if (strcmp(reply->element[0]->str, "unsubscribe") == 0) {
                    NSLog(@"REDIS: UNSUBSCRIBE : Disconnecting...");
                    redisAsyncDisconnect(ctx);
                    return;
                }
                HandlerBundle hb = (HandlerBundle)data;
                (hb->handler)(reply->element[2]->str, hb->data);
            }
        }
    }
}

/*
void rcUnsubscribe(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        
    }
    NSLog(@"REDIS: UNSUBSCRIBE : Disconnecting...");
    redisAsyncDisconnect(ctx);
}
*/

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("REDIS: CONNECT : Error: %s\n", c->errstr);
        return;
    }
    printf("REDIS: CONNECT : Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        NSLog(@"REDIS: DISCONNECT : Error: %s\n", c->errstr);
        return;
    }
    NSLog(@"REDIS : DISCONNECT : Disconnected.");
}

HandlerBundle makeHandlerBundle(mpCallback callback, void *data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = data;
    if (callback) {
        //NSLog(@"Setting callback in bundle...");
        hb->handler = (__bridge void *) callback;
    }
    hb->semaphore = sema;
    return hb;
}

HandlerBundle makeHandlerBundleC(mpCallbackC callback, void *data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = data;
    hb->handler = NULL;
    if (callback) {
        //NSLog(@"Setting callback in bundle...");
        hb->handler = callback;
    }
    hb->semaphore = nil;
    if (sema) {
        hb->semaphore = sema;
    }
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
    
    TSEventDispatcher *_dispatcher;
    NSMutableDictionary *_subscribers;
    
    // Long-living redis synchronous contexts.
    redisContext *_blockingContext;
    
}

- (id)initWithIPAddress:(NSString *)ip port:(NSUInteger)port {
    self = [super init];
    if (self) {
        signal(SIGPIPE, SIG_IGN);
        _redisHost = [NSHost hostWithAddress:ip];
        _redisPort = port;
        
        // Initialize the subscriber list
        _subscribers = [[NSMutableDictionary alloc] init];
        
        _dispatcher = [[TSEventDispatcher alloc] init];
        if (_dispatcher) {
            // Setting up the asynchronous publish context
            _asyncPubSessionContext = [self connectAndDispatch];
        } else {
            DLog(@"REDIS: INIT : Unable to initialize event dispatcher, exiting Redis controller...");
            return nil;
        }
        
        _blockingContext = [self connect];
        if (!_blockingContext) {
            DLog(@"REDIS: Unable to initialize synchronous Redis context.");
            return nil;
        }
        
        
    }

    return self;
}

- (id)init {
    return [self initWithIPAddress:@REDIS_IP port:REDIS_PORT];
}

- (BOOL)processReply:(redisContext *)ctx withReply:(void *)r andData:(void *)data {
    redisReply *reply = r;
    if (reply == NULL) {
        NSLog(@"REDIS: The reply was null, checking context...");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    NSLog(@"REDIS: Error occured : %s", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    NSLog(@"REDIS:  The server closed the connection which resulted in an empty read. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    NSLog(@"REDIS:  There was an error while parsing the protocol. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    NSLog(@"REDIS:  Possible error when resolving hostname. : %s", ctx->errstr);
                    break;
                    
                default:
                    NSLog(@"REDIS: Unknown error. : %s", ctx->errstr);
                    break;
            }
        } else {
            NSLog(@"Context is null as well. Aborting.");
        }
        return NO;
    }
    
    switch (reply->type) {
        case REDIS_REPLY_STATUS:
            NSLog(@"REDIS: REDIS_REPLY_STATUS : %s", reply->str);
            break;
        case REDIS_REPLY_ERROR:
            NSLog(@"REDIS: ERROR! :REDIS_REPLY_ERROR : %s", reply->str);
            break;
        case REDIS_REPLY_INTEGER:
            NSLog(@"REDIS: REDIS_REPLY_INTEGER : %lld", reply->integer);
            break;
        case REDIS_REPLY_NIL:
            NSLog(@"REDIS: REDIS_REPLY_NIL : no data.");
            break;
        case REDIS_REPLY_STRING:
            NSLog(@"REDIS: REDIS_REPLY_STRING : %s", reply->str);
            break;
        case REDIS_REPLY_ARRAY:
            NSLog(@"REDIS: REDIS_REPLY_ARRAY : Number of elements : %zd", reply->elements);
            break;
            
        default:
            break;
    }
    
    return YES;
}

- (redisContext *)connect {
    redisContext *context = redisConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
    if (context && context->err) {
        DLog(@"REDIS: SYNC CONNECT : There was an error establishing the connection : %s", context->errstr);
        context = NULL;
        return context;
    }
    
    return context;
}

- (redisAsyncContext *)connectAndDispatch {
    redisAsyncContext *localAsyncCtx = redisAsyncConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
    if (localAsyncCtx->err) {
        ALog(@"REDIS: Error establishing connection : %s\n", localAsyncCtx->errstr);
        return NULL;
    } else {
        DLog(@"REDIS: Establishing connection to %@\n", [[self redisHost] address]);
    }
    DLog(@"REDIS: Dispatching context...");
    uint result = [_dispatcher dispatchWithContext:localAsyncCtx];
    if (result != REDIS_OK) {
        ALog(@"REDIS: Error dispatching Redis context to event loop : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    DLog(@"REDIS: Setting disconnect callback...");
    result = redisAsyncSetDisconnectCallback(localAsyncCtx, disconnectCallback);
    if (result != REDIS_OK) {
        ALog(@"REDIS: Error setting disconnect callback : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    
    return localAsyncCtx;
}

- (NSString *)subscribeToChannels:(NSArray *)channels withCallback:(mpCallbackC)callback andContext:(void *)context {
    NSMutableString *subCmd = [[NSMutableString alloc] initWithFormat:@"SUBSCRIBE %@", [channels componentsJoinedByString:@" "]];
    DLog(@"REDIS: Subscription command [%@]", subCmd);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    HandlerBundle bundle = NULL;
    NSString *subscriberID = nil;
    char *cmd = (char *)malloc((sizeof(char)) * strlen([subCmd UTF8String]));
    strcpy(cmd, [subCmd UTF8String]);
    if (localAsyncCtx) {
        bundle = makeHandlerBundleC(callback, context, nil);
        uint result = redisAsyncCommand(localAsyncCtx, rcSubscribe, bundle, cmd);
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering SUBSCRIBE command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            return nil;
        }
        subscriberID = [TSClientIdentifier createUUID];
        DLog(@"REDIS: Registering new subscriber...");
        TSRedisSubscriptionContext *subscription = [[TSRedisSubscriptionContext alloc] initWithRedisContext:localAsyncCtx
                                                                                                   channels:channels bundle:bundle];
        [_subscribers setObject:subscription forKey:subscriberID];
    } else {
        DLog(@"REDIS: Unable to complete SUBSCRIBE.");
    }
    
    //free(cmd);
    return subscriberID;
}

- (void)unsubscribe:(NSString *)subscriptionID {
    TSRedisSubscriptionContext *context = [_subscribers objectForKey:subscriptionID];
    if (context) {
        DLog(@"REDIS: Found subscriber...");
        redisAsyncContext *redisContext = [context context];
        uint result = redisAsyncCommand(redisContext, NULL, NULL, "UNSUBSCRIBE");
        if (result != REDIS_OK) {
            ALog(@"REDIS : Error buffering UNSUBSCRIBE command for this session : %s", redisContext->errstr);
        }
        //DLog(@"REDIS: Disconnecting subscription context...");
        //redisAsyncDisconnect(redisContext);
        [_subscribers removeObjectForKey:subscriptionID];
    }
}

- (void)unsubscribeAll {
    DLog(@"REDIS: Unsubscribing from all channels...");
    for (id obj in [_subscribers objectEnumerator]) {
        TSRedisSubscriptionContext *context = (TSRedisSubscriptionContext *)obj;
        redisAsyncContext *redisContext = [context context];
        DLog(@"REDIS: Unsubscribing from : %@", [[context channels] componentsJoinedByString:@" "]);
        redisAsyncCommand(redisContext, NULL, NULL, "UNSUBSCRIBE");  // TODO: Check return!
        //redisAsyncDisconnect(redisContext); // TODO: Check return!
        [context freeBundle];
    }
    [_subscribers removeAllObjects];
}


- (void)publishObject:(NSString *)object toChannel:(NSString *)channel {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ %%b", channel];
    DLog(@"REDIS: Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, [pubCmd UTF8String], [object UTF8String], strlen([object UTF8String]));
}

- (void)publish:(const char *)bytes toChannel:(NSString *)channel {
    NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ %%b", channel];
    DLog(@"REDIS: Publish command [%@]", pubCmd);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, [pubCmd UTF8String], bytes, strlen(bytes));
}

-(void)setStringValueAsynchronous:(NSString *)stringValue forKey:(NSString *)key {
    DLog(@"REDIS: Setting value [%@] for key [%@]...", stringValue, key);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    HandlerBundle bundle = NULL;
    if (localAsyncCtx) {
        dispatch_semaphore_t set = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &set);
        uint result = redisAsyncCommand(localAsyncCtx, rcSet, bundle, "SET %s %b", [key UTF8String], [stringValue UTF8String],
                                        strlen([stringValue UTF8String]));
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering SET command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            return;
        }
        dispatch_semaphore_wait(set, DISPATCH_TIME_FOREVER);
    } else {
        DLog(@"REDIS: Unable to complete SET.");
    }
    
    freeBundle(bundle);
    return;
}

-(void)setStringValue:(NSString *)stringValue forKey:(NSString *)aKey {
    DLog(@"REDIS: Setting value [%@] for key [%@]...", stringValue, aKey);
    char *key = (char *)malloc((sizeof(char) * strlen([aKey UTF8String])));
    strcpy(key, [aKey UTF8String]);
    char *value = (char *)malloc((sizeof(char) * strlen([stringValue UTF8String])));
    strcpy(value, [stringValue UTF8String]);
    redisReply *reply = NULL;
    
    void *response = redisCommand(_blockingContext, "SET %s %b", key, value, strlen(value));
    if ([self processReply:_blockingContext withReply:response andData:NULL]) {
        reply = (redisReply *)response;
        if (reply->type == REDIS_REPLY_STATUS) {
            if (strcmp(reply->str, "OK")) {
                DLog(@"REDIS: SET replied with OK.");
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            DLog(@"REDIS: SET replied with (nil).");
        }
    } else {
        DLog(@"REDIS: Error processing SET.");
    }
    
    DLog(@"REDIS: SET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
        free(value);
    }
    
    return;
}

-(BOOL)setNXStringValue:(NSString *)stringValue forKey:(NSString *)key {
    DLog(@"REDIS: NX : Setting value [%@] for key [%@]...", stringValue, key);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    BOOL isSet = NO;
    HandlerBundle bundle = NULL;
    if (localAsyncCtx) {
        dispatch_semaphore_t setnx = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &setnx);
        uint result = redisAsyncCommand(localAsyncCtx, rcSet, bundle, "SET %s %b NX", [key UTF8String], [stringValue UTF8String],
                                                                                        strlen([stringValue UTF8String]));
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering SETNX command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            return NO;
        }
        dispatch_semaphore_wait(setnx, DISPATCH_TIME_FOREVER);
        if (bundle) {
            if (bundle->int_data) {
                DLog(@"REDIS: NX : Key was set.");
                isSet = YES;
            }
        }
    } else {
        DLog(@"REDIS : Unable to complete SETNX.");
    }
    
    freeBundle(bundle);
    return isSet;
}

-(NSString *)stringValueForKey:(NSString *)aKey {
    DLog(@"REDIS: Getting value for key [%@]...", aKey);
    char *key = (char *)malloc((sizeof(char) * strlen([aKey UTF8String])));
    strcpy(key, [aKey UTF8String]);
    NSString *stringValue = nil;
    redisReply *reply = NULL;
    void *response = redisCommand(_blockingContext, "GET %s", key);
    if ([self processReply:_blockingContext withReply:response andData:NULL]) {
        reply = (redisReply *)response;
        if (reply->type == REDIS_REPLY_STRING) {
            DLog(@"REDIS: GET : Processing GET reply..");
            stringValue = [NSString stringWithCString:reply->str encoding:NSUTF8StringEncoding];
        } else {
            DLog(@"REDIS: GET replied with (nil).");
        }
        
    } else {
        DLog(@"REDIS: Error processing GET.");
    }
    NSLog(@"REDIS: GET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
    }
    
    return stringValue;
}

-(NSString *)stringValueForKeyAsynchronous:(NSString *)key {
    DLog(@"REDIS: Getting value for key [%@]...", key);
    NSString *stringValue = nil;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t get = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &get);
        uint result = redisAsyncCommand(localAsyncCtx, rcGet, bundle, "GET %s", [key UTF8String]);
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering GET command for this session : %s", localAsyncCtx->errstr);
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
        DLog(@"REDIS: Unable to complete GET.");
    }
    
    free(bundle->data);
    free(bundle); // IMP!
    
    return stringValue;
}

-(NSUInteger)incrementKey:(NSString *)key {
    DLog(@"REDIS: Incrementing key [%@]...", key);
    NSUInteger incremented = UINT32_MAX;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t incr = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &incr);
        uint result = redisAsyncCommand(localAsyncCtx, rcIncr, bundle, "INCR %s", [key UTF8String]);
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering INCR command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            return incremented;
        }
        dispatch_semaphore_wait(incr, DISPATCH_TIME_FOREVER);
        if (bundle) {
            incremented = bundle->int_data;
        }
    } else {
        DLog(@"REDIS: Unable to complete INCR.");
    }
    
    free(bundle); // IMP!
    return incremented;
}

-(NSUInteger)deleteKey:(NSString *)aKey {
    DLog(@"REDIS: Deleting key [%@]...", aKey);
    char *key = (char *)malloc((sizeof(char) * strlen([aKey UTF8String])));
    strcpy(key, [aKey UTF8String]);
    redisReply *reply = NULL;
    NSUInteger deleted = 0;
    
    void *response = redisCommand(_blockingContext, "DEL %s", key);
    if ([self processReply:_blockingContext withReply:response andData:NULL]) {
        reply = (redisReply *)response;
        if (reply->type == REDIS_REPLY_INTEGER) {
            deleted = reply->integer;
        } else {
            DLog(@"REDIS: DEL replied with (nil).");
        }
        
    } else {
        DLog(@"REDIS: Error processing DEL.");
    }
    NSLog(@"REDIS: DEL : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
    }
    
    return deleted;
}

/*
-(NSUInteger)deleteKey:(NSString *)key {
    DLog(@"REDIS: Deleting key [%@]...", key);
    NSUInteger deleted = 0;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t del = dispatch_semaphore_create(0);
        bundle = makeHandlerBundle(nil, NULL, &del);
        uint result = redisAsyncCommand(localAsyncCtx, rcDel, bundle, "DEL %s", [key UTF8String]);
        if (result != REDIS_OK) {
            ALog(@"REDIS: Error buffering DEL command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            return deleted;
        }
        dispatch_semaphore_wait(del, DISPATCH_TIME_FOREVER);
        if (bundle) {
            deleted = bundle->int_data;
        }
    } else {
        DLog(@"REDIS: Unable to complete INCR.");
    }
    
    free(bundle); // IMP!
    return deleted;
}
*/

/*
-(void)setDictionaryValue:(NSDictionary *)dictionary forKey:(NSString *)key;
-(NSDictionary *)dictionaryValueForKey:(NSString *)key;
-(NSArray *)dictionaryKeysForKey:(NSString *)key;
*/

- (void)dealloc {
    _subscribers = nil;
    DLog(@"REDIS: Disconnecting from publish context...");
    
    if (!_asyncPubSessionContext->err) {
        redisAsyncDisconnect(_asyncPubSessionContext);
    }
    _asyncPubSessionContext = nil;
    
    DLog(@"REDIS: Deallocating blocking context...");
    redisFree(_blockingContext);
}

@end
