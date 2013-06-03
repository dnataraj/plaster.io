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

/*
void _signal(const char *caller, void *bundle) {
    if (bundle) {
        HandlerBundle hb = (HandlerBundle)bundle;
        if (hb->semaphore) {
            printf("REDIS: %s : Signalling...", caller);
            dispatch_semaphore_signal(*(hb->semaphore));
        }
    }
}
*/

BOOL rcProcessReply(redisAsyncContext *ctx, void *r, void *data) {
    redisReply *reply = r;
    if (reply == NULL) {
        printf("REDIS: The reply was null, checking context...");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    printf("REDIS: Error occured : %s", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    printf("REDIS:  The server closed the connection which resulted in an empty read. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    printf("REDIS:  There was an error while parsing the protocol. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    printf("REDIS:  Possible error when resolving hostname. : %s", ctx->errstr);
                    break;
                    
                default:
                    printf("REDIS: Unknown error. : %s", ctx->errstr);
                    break;
            }
        } else {
            printf("Context is null as well. Aborting.");
        }
        return NO;
    }
    
    switch (reply->type) {
        case REDIS_REPLY_STATUS:
            printf("REDIS: REDIS_REPLY_STATUS : %s", reply->str);
            break;
        case REDIS_REPLY_ERROR:
            printf("REDIS: ERROR! :REDIS_REPLY_ERROR : %s", reply->str);
            break;
        case REDIS_REPLY_INTEGER:
            printf("REDIS: REDIS_REPLY_INTEGER : %lld", reply->integer);
            break;
        case REDIS_REPLY_NIL:
            printf("REDIS: REDIS_REPLY_NIL : no data.");
            break;
        case REDIS_REPLY_STRING:
            printf("REDIS: REDIS_REPLY_STRING : %s", reply->str);
            break;
        case REDIS_REPLY_ARRAY:
            printf("REDIS: REDIS_REPLY_ARRAY : Number of elements : %zd", reply->elements);
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
                printf("REDIS: SET replied with OK.");
                if (data) {
                    HandlerBundle hb = (HandlerBundle)data;
                    hb->int_data = 1;
                }
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            printf("REDIS: SET replied with (nil).");
            if (data) {
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = 0;
            }
            
        }
        printf("REDIS: SET : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    //_signal("SET", data);
    return;
}

void rcGet(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_STRING) {
            if (data) {
                printf("REDIS: GET : Processing GET reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->data = (char *)malloc(strlen(reply->str));
                strcpy(hb->data, reply->str);
            }
        }
        
        printf("REDIS: GET : Disconnecting...");
        redisAsyncDisconnect(ctx);        
    }
    
    //_signal("GET", data);
    return;
}

void rcIncr(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                printf("REDIS: INCR : Processing INCR reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        printf("REDIS: INCR : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    
    //_signal("INCR", data);
    return;
}

void rcDel(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                printf("REDIS: DEL : Processing DEL reply..");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        printf("REDIS: DEL : Disconnecting...");
        redisAsyncDisconnect(ctx);
    }
    
    //_signal("DEL", data);
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
                    printf("REDIS: UNSUBSCRIBE : Disconnecting...");
                    redisAsyncDisconnect(ctx);
                    return;
                }
                if (data != NULL) {
                    HandlerBundle hb = (HandlerBundle)data;
                    (hb->handler)(reply->element[2]->str, hb->data);
                } else {
                    printf("REDIS: SUBSCRIBE : Invalid handler : %p", data);
                }
            }
        }
    }
}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("REDIS: CONNECT : Error: %s\n", c->errstr);
        return;
    }
    printf("REDIS: CONNECT : Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("REDIS: DISCONNECT : Error: %s\n", c->errstr);
        return;
    }
    printf("REDIS : DISCONNECT : Disconnected.");
}

HandlerBundle makeHandlerBundleC(mpCallbackC callback, void *data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = data;
    hb->handler = NULL;
    if (callback) {
        //NSLog(@"Setting callback in bundle...");
        hb->handler = callback;
    }
    /*
    hb->semaphore = nil;
    if (sema) {
        hb->semaphore = sema;
    }
    */
    return hb;
}

HandlerBundle makeHandlerBundleObjC(mpCallback callback, id data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(HandlerBundle));
    hb->data = (__bridge void *)(data);
    if (callback) {
        hb->handler = (__bridge void *) callback;
    }
    //hb->semaphore = sema;
    return hb;
}

void freeBundle(HandlerBundle hb) {
    free(hb->data);
    //dispatch_release(*hb->semaphore);
    //hb->semaphore = nil;
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
        _redisHost = [[NSHost hostWithAddress:ip] retain];
        _redisPort = port;
        
        // Initialize the subscriber list
        _subscribers = [[NSMutableDictionary alloc] init];
        
        _dispatcher = [[TSEventDispatcher alloc] init];
        if (_dispatcher) {
            // Setting up the asynchronous publish context
            _asyncPubSessionContext = [self connectAndDispatch];
        } else {
            NSLog(@"REDIS: INIT : Unable to initialize event dispatcher, exiting Redis controller...");
            return nil;
        }
        
        _blockingContext = [self connect];
        if (!_blockingContext) {
            NSLog(@"REDIS: Unable to initialize synchronous Redis context.");
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
    signal(SIGPIPE, SIG_IGN);
    redisContext *context = redisConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
    if (context && context->err) {
        NSLog(@"REDIS: SYNC CONNECT : There was an error establishing the connection : %s", context->errstr);
        context = NULL;
        return context;
    }
    
    return context;
}

- (redisAsyncContext *)connectAndDispatch {
    signal(SIGPIPE, SIG_IGN);
    NSString *address = [[self redisHost] address];
    const char *temp = [address UTF8String];
    char *addr = malloc(sizeof(char) * strlen(temp));
    NSAssert(addr != NULL, @"REDIS: ERROR: Unable to malloc for string!");
    strcpy(addr, temp);
    redisAsyncContext *localAsyncCtx = redisAsyncConnect(addr, (uint)[self redisPort]);
    if (localAsyncCtx->err) {
        NSLog(@"REDIS: Error establishing connection : %s\n", localAsyncCtx->errstr);
        return NULL;
    } else {
        NSLog(@"REDIS: Establishing connection to %@\n", [[self redisHost] address]);
    }
    NSLog(@"REDIS: Dispatching context...");
    uint result = [_dispatcher dispatchWithContext:localAsyncCtx];
    if (result != REDIS_OK) {
        NSLog(@"REDIS: Error dispatching Redis context to event loop : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    NSLog(@"REDIS: Setting disconnect callback...");
    result = redisAsyncSetDisconnectCallback(localAsyncCtx, disconnectCallback);
    if (result != REDIS_OK) {
        NSLog(@"REDIS: Error setting disconnect callback : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        return NULL;
    }
    
    free(addr);
    return localAsyncCtx;
}

- (NSString *)subscribeToChannels:(NSArray *)someChannels withCallback:(mpCallbackC)callback andContext:(void *)context {
    //NSString *channels = [someChannels componentsJoinedByString:@" "];
    NSString *channels = [[NSString alloc] initWithString:[someChannels componentsJoinedByString:@" "]];
    //NSString *subCmd = [NSString stringWithFormat:@"SUBSCRIBE %@", channels];
    NSString *command = [[NSString alloc] initWithFormat:@"SUBSCRIBE %@", channels];
    NSLog(@"REDIS: Subscription command [%@]", command);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    HandlerBundle bundle = NULL;
    NSString *subscriberID = nil;
    const char *temp = [command UTF8String];
    char *cmd = malloc((sizeof(char)) * strlen(temp));
    strcpy(cmd, temp);
    if (localAsyncCtx) {
        bundle = makeHandlerBundleC(callback, context, nil);
        uint result = redisAsyncCommand(localAsyncCtx, rcSubscribe, bundle, cmd);
        if (result != REDIS_OK) {
            NSLog(@"REDIS: Error buffering SUBSCRIBE command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            freeBundle(bundle);
            free(cmd);  //TODO : Analyse this.
            [channels release];
            [command release];
            return nil;
        }
        subscriberID = [TSClientIdentifier createUUID];
        NSLog(@"REDIS: Registering new subscriber...");
        TSRedisSubscriptionContext *subscription = [[TSRedisSubscriptionContext alloc] initWithRedisContext:localAsyncCtx
                                                                                                   channels:someChannels bundle:bundle];
        [_subscribers setObject:subscription forKey:subscriberID];
        [subscription release];
        //[subscriberID release];
    } else {
        NSLog(@"REDIS: Unable to complete SUBSCRIBE.");
    }
    
    free(cmd);  //TODO : Analyse this.
    [channels release];
    [command release];
    
    return nil;
}

- (void)unsubscribe:(NSString *)subscriptionID {
    TSRedisSubscriptionContext *context = [_subscribers objectForKey:subscriptionID];
    if (context) {
        NSLog(@"REDIS: Found subscriber...");
        redisAsyncContext *redisContext = [context context];
        uint result = redisAsyncCommand(redisContext, NULL, NULL, "UNSUBSCRIBE");
        if (result != REDIS_OK) {
            NSLog(@"REDIS : Error buffering UNSUBSCRIBE command for this session : %s", redisContext->errstr);
        }
        //NSLog(@"REDIS: Disconnecting subscription context...");
        //redisAsyAncDisconnect(redisContext);
        [_subscribers removeObjectForKey:subscriptionID];
    }
}

- (void)unsubscribeAll {
    NSLog(@"REDIS: Unsubscribing from all channels...");
    for (id obj in [_subscribers objectEnumerator]) {
        TSRedisSubscriptionContext *context = (TSRedisSubscriptionContext *)obj;
        redisAsyncContext *redisContext = [context context];
        NSLog(@"REDIS: Unsubscribing from : %@", [[context channels] componentsJoinedByString:@" "]);
        redisAsyncCommand(redisContext, NULL, NULL, "UNSUBSCRIBE");  // TODO: Check return!
        //redisAsyncDisconnect(redisContext); // TODO: Check return!
        [context freeBundle];
    }
    [_subscribers removeAllObjects];
}

- (void)publishObject:(NSString *)anObject toChannel:(NSString *)channel {
    //NSMutableString *pubCmd = [[NSMutableString alloc] initWithFormat:@"PUBLISH %@ %%b", channel];
    NSString *command = [NSString stringWithFormat:@"PUBLISH %@ %%b", channel];
    NSLog(@"REDIS: Publish command [%@]", command);
    const char *temp1 = [anObject UTF8String];
    char *obj = malloc(sizeof(char) * strlen(temp1));
    NSAssert(obj != NULL, @"REDIS: ERROR: String allocation failed!");
    strcpy(obj, temp1);
    printf("obj : %s\n", obj);
    const char *temp2 = [command UTF8String];
    char *publish = malloc(sizeof(char) * (strlen(temp2)));
    NSAssert(publish != NULL, @"REDIS: ERROR: String allocation failed!");
    strcpy(publish, temp2);
    printf("publish : %s\n", publish);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, publish, obj, strlen(obj));
    free(obj);
    free(publish);
}

- (void)publish:(const char *)bytes toChannel:(NSString *)channel {
    NSMutableString *command = [NSMutableString stringWithFormat:@"PUBLISH %@ %%b", channel];
    NSLog(@"REDIS: Publish command [%@]", command);
    const char *temp = [command UTF8String];
    char *publish = malloc(sizeof(char) * (strlen([command UTF8String])));
    strcpy(publish, temp);
    redisAsyncCommand(_asyncPubSessionContext, NULL, NULL, publish, bytes, strlen(bytes));
    free(publish);
}

-(void)setStringValue:(NSString *)stringValue forKey:(NSString *)aKey {
    NSLog(@"REDIS: Setting value [%@] for key [%@]...", stringValue, aKey);
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
                NSLog(@"REDIS: SET replied with OK.");
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            NSLog(@"REDIS: SET replied with (nil).");
        }
    } else {
        NSLog(@"REDIS: Error processing SET.");
    }
    
    NSLog(@"REDIS: SET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
        free(value);
    }
    
    return;
}

-(NSString *)stringValueForKey:(NSString *)aKey {
    NSLog(@"REDIS: Getting value for key [%@]...", aKey);
    char *key = (char *)malloc((sizeof(char) * strlen([aKey UTF8String])));
    strcpy(key, [aKey UTF8String]);
    NSString *stringValue = nil;
    redisReply *reply = NULL;
    void *response = redisCommand(_blockingContext, "GET %s", key);
    if ([self processReply:_blockingContext withReply:response andData:NULL]) {
        reply = (redisReply *)response;
        if (reply->type == REDIS_REPLY_STRING) {
            NSLog(@"REDIS: GET : Processing GET reply..");
            stringValue = [NSString stringWithCString:reply->str encoding:NSUTF8StringEncoding];
        } else {
            NSLog(@"REDIS: GET replied with (nil).");
        }
        
    } else {
        NSLog(@"REDIS: Error processing GET.");
    }
    NSLog(@"REDIS: GET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
    }
    
    return stringValue;
}

-(NSUInteger)incrementKey:(NSString *)key {
    NSLog(@"REDIS: Incrementing key [%@]...", key);
    NSUInteger incremented = UINT32_MAX;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t incr = dispatch_semaphore_create(0);
        bundle = makeHandlerBundleC(nil, NULL, &incr);
        uint result = redisAsyncCommand(localAsyncCtx, rcIncr, bundle, "INCR %s", [key UTF8String]);
        if (result != REDIS_OK) {
            NSLog(@"REDIS: Error buffering INCR command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            return incremented;
        }
        dispatch_semaphore_wait(incr, DISPATCH_TIME_FOREVER);
        if (bundle) {
            incremented = bundle->int_data;
        }
    } else {
        NSLog(@"REDIS: Unable to complete INCR.");
    }
    
    free(bundle); // IMP!
    return incremented;
}

-(NSUInteger)deleteKey:(NSString *)aKey {
    NSLog(@"REDIS: Deleting key [%@]...", aKey);
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
            NSLog(@"REDIS: DEL replied with (nil).");
        }
        
    } else {
        NSLog(@"REDIS: Error processing DEL.");
    }
    NSLog(@"REDIS: DEL : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
    }
    
    return deleted;
}

- (void)dealloc {
    [_subscribers release];
    _subscribers = nil;
    NSLog(@"REDIS: Disconnecting from publish context...");
    
    if (!_asyncPubSessionContext->err) {
        redisAsyncDisconnect(_asyncPubSessionContext);
    }
    _asyncPubSessionContext = nil;
    
    NSLog(@"REDIS: Deallocating blocking context...");
    redisFree(_blockingContext);
    _blockingContext = nil;
    
    [_dispatcher release];
    
    [super dealloc];
}

@end
