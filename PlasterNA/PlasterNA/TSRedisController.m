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

BOOL rcProcessReply(redisAsyncContext *ctx, void *r, void *data) {
    redisReply *reply = r;
    if (reply == NULL) {
        printf("REDIS: The reply was null, checking context...\n");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    printf("REDIS: Error occured : %s\n", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    printf("REDIS:  The server closed the connection which resulted in an empty read. : %s\n", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    printf("REDIS:  There was an error while parsing the protocol. : %s\n", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    printf("REDIS:  Possible error when resolving hostname. : %s\n", ctx->errstr);
                    break;
                    
                default:
                    printf("REDIS: Unknown error. : %s\n", ctx->errstr);
                    break;
            }
        } else {
            printf("Context is null as well. Aborting.\n");
        }
        return NO;
    }
    /*
    switch (reply->type) {
        case REDIS_REPLY_ERROR:
            printf("REDIS: ERROR! :REDIS_REPLY_ERROR : %s\n", reply->str);
            break;
        
        case REDIS_REPLY_STATUS:
            printf("REDIS: REDIS_REPLY_STATUS : %s\n", reply->str);
            break;
        case REDIS_REPLY_INTEGER:
            printf("REDIS: REDIS_REPLY_INTEGER : %lld\n", reply->integer);
            break;
        case REDIS_REPLY_NIL:
            printf("REDIS: REDIS_REPLY_NIL : no data.\n");
            break;
        case REDIS_REPLY_STRING:
            printf("REDIS: REDIS_REPLY_STRING : %s\n", reply->str);
            break;
        case REDIS_REPLY_ARRAY:
            printf("REDIS: REDIS_REPLY_ARRAY : Number of elements : %zd\n", reply->elements);
            break;
          
        default:
            break;
    }
    */
    
    return YES;
}

void rcSet(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_STATUS) {
            if (strcmp(reply->str, "OK")) {
                printf("REDIS: SET replied with OK.\n");
                if (data) {
                    HandlerBundle hb = (HandlerBundle)data;
                    hb->int_data = 1;
                }
            }
        } else if (reply->type == REDIS_REPLY_NIL) {
            printf("REDIS: SET replied with (nil).\n");
            if (data) {
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = 0;
            }
            
        }
        printf("REDIS: SET : Disconnecting...\n");
        redisAsyncDisconnect(ctx);
    }
    return;
}

void rcGet(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_STRING) {
            if (data) {
                printf("REDIS: GET : Processing GET reply..\n");
                HandlerBundle hb = (HandlerBundle)data;
                hb->data = (char *)malloc(strlen(reply->str));
                strcpy(hb->data, reply->str);
            }
        }
        
        printf("REDIS: GET : Disconnecting...\n");
        redisAsyncDisconnect(ctx);        
    }
    return;
}

void rcIncr(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                printf("REDIS: INCR : Processing INCR reply..\n");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        printf("REDIS: INCR : Disconnecting...\n");
        redisAsyncDisconnect(ctx);
    }
    return;
}

void rcDel(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_INTEGER) {
            if (data) {
                printf("REDIS: DEL : Processing DEL reply..\n");
                HandlerBundle hb = (HandlerBundle)data;
                hb->int_data = reply->integer;
            }
        }
        
        printf("REDIS: DEL : Disconnecting...\n");
        redisAsyncDisconnect(ctx);
    }
    return;
}

void rcSubscribe(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_ARRAY) {
            /*
            for (int j = 0; j < reply->elements; j++) {
                printf("%u) %s\n", j, reply->element[j]->str);
            }
            */
            if (strcmp(reply->element[0]->str, "UNSUBSCRIBE") == 0) {
                printf("REDIS: UNSUBSCRIBE : Disconnecting...\n");
                redisAsyncDisconnect(ctx);
                return;
            }
            if (reply->elements > 2 && reply->element[2]->str) {
                if (data != NULL) {
                    HandlerBundle hb = (HandlerBundle)data;
                    if (hb->handler) {
                        printf("Handling incoming message : %s\n", reply->element[2]->str);
                        (*hb->handler)(reply->element[2]->str, hb->data);
                    }
                } else {
                    printf("REDIS: SUBSCRIBE : Invalid handler : %p\n", data);
                }
            }
        }
    }
}

void rcSubscribeWithOptions(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {
        redisReply *reply = r;
        if (reply->type == REDIS_REPLY_ARRAY) {
            if (strcmp(reply->element[0]->str, "UNSUBSCRIBE") == 0) {
                printf("REDIS: UNSUBSCRIBE : Disconnecting...\n");
                redisAsyncDisconnect(ctx);
                return;
            }
            if (reply->elements > 2 && reply->element[2]->str) {
                if (data != NULL) {
                    NSDictionary *options = (NSDictionary *)data;
                    if (options) {
                        NSString *handlerName = [options objectForKey:@"HANDLER_NAME"];
                        NSDictionary *handlerTable = [options objectForKey:@"HANDLER_TABLE"];
                        NSDictionary *handlerOptions = [handlerTable objectForKey:handlerName];
                        if (handlerOptions) {
                            id target = [handlerOptions objectForKey:@"target"];
                            NSInvocation *invocation = [handlerOptions objectForKey:@"invocation"];
                            if (invocation) {
                                //NSLog(@"REDIS: SUB INV : Invoking on : %@", [target class]);
                                //NSLog(@"REDIS: SUB INV : With selector : %@", NSStringFromSelector([invocation selector]));
                                [invocation setTarget:target];
                                //char *arg = (char *)malloc(sizeof(char) * strlen(reply->element[2]->str));
                                char *arg = (char *)calloc(strlen(reply->element[2]->str), sizeof(char));
                                if (arg == NULL) {
                                    printf("REDIS: SUBSCRIBE : Unable to allocate memory for handler argument");
                                    return;
                                }
                                strcpy(arg, reply->element[2]->str);
                                [invocation retainArguments];
                                [invocation setArgument:&arg atIndex:2];
                                [invocation invoke];
                                free(arg);
                            }
                            
                        }
                    }
                } else {
                    printf("REDIS: SUBSCRIBE : Invalid handler : %p\n", data);
                }
            }
        }
    }
}

void rcPublish(redisAsyncContext *ctx, void *r, void *data) {
    if (rcProcessReply(ctx, r, data)) {        
        printf("REDIS: PUBLISH : Disconnecting...\n");
        redisAsyncDisconnect(ctx);
    }
    return;
}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("REDIS: CONNECT : Error: %s\n", c->errstr);
        return;
    }
    //printf("REDIS: CONNECT : Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("REDIS: DISCONNECT : Error: %s\n", c->errstr);
        return;
    }
    printf("REDIS : DISCONNECT : Disconnected.\n");
}

HandlerBundle makeHandlerBundleC(mpCallback callback, void *data, dispatch_semaphore_t *sema) {
    HandlerBundle hb = (HandlerBundle)malloc(sizeof(struct _handlerbundle));
    if (hb) {
        hb->data = data;
        hb->handler = NULL;
        if (callback) {
            hb->handler = callback;
        }
        return hb;
    }
    return NULL;
}

void freeBundle(HandlerBundle hb) {
    free(hb->data);
    free(hb);
}

@implementation TSRedisController {
    redisAsyncContext *_asyncPubSessionContext;
    redisAsyncContext *_subscribers[100];
    
    TSEventDispatcher *_dispatcher;
    
    // Long-living redis synchronous contexts.
    //redisContext *_blockingContext;
}

- (id)initWithIPAddress:(NSString *)ip port:(NSUInteger)port {
    self = [super init];
    if (self) {
        _redisHost = [[NSHost hostWithAddress:ip] retain];
        _redisPort = port;
        
        // Initialize the subscriber list
        //_subscribers = [[NSMutableDictionary alloc] init];
        
        _dispatcher = [[TSEventDispatcher alloc] init];
        if (_dispatcher) {
            // Setting up the asynchronous publish context
            _asyncPubSessionContext = [self connectAndDispatch];
        } else {
            DLog(@"REDIS: INIT : Unable to initialize event dispatcher, exiting Redis controller...");
            return nil;
        }
        
        /*
        _blockingContext = [self connect];
        if (!_blockingContext) {
            DLog(@"REDIS: Unable to initialize synchronous Redis context.");
            return nil;
        }
        */
        
        // Zero the number of subscribers
        _numSubscribers = 0;
    }

    return self;
}

- (id)init {
    return [self initWithIPAddress:@REDIS_IP port:REDIS_PORT];
}

- (BOOL)processReply:(redisContext *)ctx withReply:(void *)r andData:(void *)data {
    redisReply *reply = r;
    if (reply == NULL) {
        DLog(@"REDIS: The reply was null, checking context...");
        if (ctx) {
            switch (ctx->err) {
                case REDIS_ERR_IO:
                    DLog(@"REDIS: Error occured : %s", strerror(errno));
                    break;
                case REDIS_ERR_EOF:
                    DLog(@"REDIS:  The server closed the connection which resulted in an empty read. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_PROTOCOL:
                    DLog(@"REDIS:  There was an error while parsing the protocol. : %s", ctx->errstr);
                    break;
                case REDIS_ERR_OTHER:
                    DLog(@"REDIS:  Possible error when resolving hostname. : %s", ctx->errstr);
                    break;
                    
                default:
                    DLog(@"REDIS: Unknown error. : %s", ctx->errstr);
                    break;
            }
        } else {
            DLog(@"Context is null as well. Aborting.");
        }
        return NO;
    }
    
    switch (reply->type) {
        case REDIS_REPLY_ERROR:
            DLog(@"REDIS: ERROR! :REDIS_REPLY_ERROR : %s", reply->str);
            break;
        /*
        case REDIS_REPLY_STATUS:
            NSLog(@"REDIS: REDIS_REPLY_STATUS : %s", reply->str);
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
        */
        default:
            break;
    }
    
    return YES;
}

- (redisContext *)connect {
    signal(SIGPIPE, SIG_IGN);
    redisContext *context = redisConnect([[[self redisHost] address] UTF8String], (uint)[self redisPort]);
    if (context && context->err) {
        DLog(@"REDIS: SYNC CONNECT : There was an error establishing the connection : %s", context->errstr);
        context = NULL;
    }
    
    return context;
}

- (redisAsyncContext *)connectAndDispatch {
    signal(SIGPIPE, SIG_IGN);
    NSString *address = [[self redisHost] address];
    const char *temp = [address UTF8String];
    char *addr = (char *)malloc(sizeof(char) * strlen(temp));
    //NSAssert(addr != NULL, @"REDIS: ERROR: Unable to malloc for string!");
    strcpy(addr, temp);
    redisAsyncContext *localAsyncCtx = redisAsyncConnect(addr, (uint)[self redisPort]);
    if (localAsyncCtx->err) {
        DLog(@"REDIS: Error establishing connection : %s\n", localAsyncCtx->errstr);
        free(addr);
        return NULL;
    } else {
        //NSLog(@"REDIS: Establishing connection to %@\n", [[self redisHost] address]);
    }
    uint result = [_dispatcher dispatchWithContext:localAsyncCtx];
    if (result != REDIS_OK) {
        DLog(@"REDIS: Error dispatching Redis context to event loop : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        free(addr);
        return NULL;
    }
    result = redisAsyncSetDisconnectCallback(localAsyncCtx, disconnectCallback);
    if (result != REDIS_OK) {
        DLog(@"REDIS: Error setting disconnect callback : %s", localAsyncCtx->errstr);
        redisAsyncDisconnect(localAsyncCtx);
        free(addr);
        return NULL;
    }
    
    free(addr);
    return localAsyncCtx;
}

- (NSUInteger)subscribeToChannels:(NSArray *)someChannels options:(NSDictionary *)someOptions {
    NSString *channels = [someChannels componentsJoinedByString:@" "];
    NSString *command = [NSString stringWithFormat:@"SUBSCRIBE %@", channels];
    //NSLog(@"REDIS: Subscription command [%@]", command);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    const char *temp = [command UTF8String];
    char *cmd = (char *)calloc(strlen(temp), (sizeof(char)));
    strcpy(cmd, temp);
    if (localAsyncCtx) {
        uint result = redisAsyncCommand(localAsyncCtx, rcSubscribeWithOptions, [someOptions retain], cmd);
        if (result != REDIS_OK) {
            DLog(@"REDIS: Error buffering SUBSCRIBE command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(cmd);
            return EXIT_FAILURE;
        }
        DLog(@"REDIS: Registering new subscriber...");
        _subscribers[[self numSubscribers]] = localAsyncCtx;
        [self setNumSubscribers:[self numSubscribers] + 1];
    } else {
        DLog(@"REDIS: Unable to complete SUBSCRIBE.");
        free(cmd);
        return EXIT_FAILURE;
    }
    
    free(cmd); 
    return EXIT_SUCCESS;
}

- (NSUInteger)subscribeToChannel:(NSString *)channel options:(NSDictionary *)someOptions {
    /*
    NSString *command = [NSString stringWithFormat:@"SUBSCRIBE %@", channel];
    NSLog(@"REDIS: Subscription command [%@]", command);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    const char *temp = [channel UTF8String];
    char *chan = (char *)calloc(strlen(temp), (sizeof(char)));
    strcpy(chan, temp);
    */
    NSString *command = [NSString stringWithFormat:@"SUBSCRIBE %@", channel];
    DLog(@"REDIS: Subscription command [%@]", command);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    const char *temp = [command UTF8String];
    char *cmd = malloc((sizeof(char)) * strlen(temp));
    strcpy(cmd, temp);
    if (localAsyncCtx) {
        uint result = redisAsyncCommand(localAsyncCtx, rcSubscribeWithOptions, [someOptions retain], cmd);
        if (result != REDIS_OK) {
            DLog(@"REDIS: Error buffering SUBSCRIBE command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(cmd);
            return EXIT_FAILURE;
        }
        DLog(@"REDIS: Registering new subscription...");
        _subscribers[[self numSubscribers]] = localAsyncCtx;
        [self setNumSubscribers:[self numSubscribers] + 1];
    } else {
        DLog(@"REDIS: Unable to complete SUBSCRIBE.");
        free(cmd);
        return EXIT_FAILURE;
    }
    
    free(cmd);
    return EXIT_SUCCESS;
}

- (void)unsubscribeAll {
    DLog(@"REDIS: Unsubscribing from all channels...");
    for (int i = 0; i < [self numSubscribers]; i++) {
        redisAsyncContext *redisContext = _subscribers[i];
        DLog(@"REDIS: Unsubscribing from : %dth subscriber...", i);
        uint result = redisAsyncCommand(redisContext, rcSubscribe, NULL, "UNSUBSCRIBE");
        if (result != REDIS_OK) {
            DLog(@"REDIS: Failed to unsubscribe from %dth subscription.", i);
        }
    }
    self.numSubscribers = 0;
}

- (NSUInteger)publishObject:(NSString *)anObject toChannel:(NSString *)channel {
    DLog(@"REDIS: Publishing object to channel : %@", channel);
    const char *temp1 = [anObject UTF8String];
    char *obj = (char *)calloc(strlen(temp1), sizeof(char));
    if (obj == NULL) {
        DLog(@"REDIS: Unable to allocate memory for publish strings.");
        return EXIT_FAILURE;
    }
    strcpy(obj, temp1);
    const char *temp2 = [channel UTF8String];
    char *chan = (char *)calloc(strlen(temp2), sizeof(char));
    if (chan == NULL) {
        DLog(@"REDIS: Unable to allocate memory for publish strings.");
        free(obj);
        return EXIT_FAILURE;
    }
    strcpy(chan, temp2);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        uint result = redisAsyncCommand(localAsyncCtx, rcPublish, NULL, "PUBLISH %s %b", chan, obj, strlen(obj));
        if (result != REDIS_OK) {
            DLog(@"REDIS: Error buffering PUBLISH command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(obj);
            free(chan);
            return EXIT_FAILURE;
        }
    } else {
        DLog(@"REDIS: Unable to complete PUBLISH OBJ.");
        free(obj);
        free(chan);
        return EXIT_FAILURE;        
    }
        
    free(obj);
    free(chan);
    return EXIT_SUCCESS;
}

- (NSUInteger)publish:(const char *)bytes toChannel:(NSString *)channel {
    DLog(@"REDIS: PUBLISH : Publishing [%zd] bytes to channel :%@ ", strlen(bytes), channel);
    const char *temp = [channel UTF8String];
    char *chan = (char *)calloc(strlen(temp), sizeof(char));
    if (chan == NULL) {
        DLog(@"REDIS: Unable to allocate memory for publish strings.");
        return EXIT_FAILURE;
    }
    strcpy(chan, temp);
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        uint result = redisAsyncCommand(localAsyncCtx, rcPublish, NULL, "PUBLISH %s %b", chan, bytes, strlen(bytes));
        if (result != REDIS_OK) {
            DLog(@"REDIS: Error buffering PUBLISH command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(chan);
            return EXIT_FAILURE;
        }
    } else {
        DLog(@"REDIS: Unable to complete PUBLISH OBJ.");
        free(chan);
        return EXIT_FAILURE;
    }
    
    free(chan);
    return EXIT_SUCCESS;
}

-(NSUInteger)setStringValue:(NSString *)stringValue forKey:(NSString *)aKey {
    DLog(@"REDIS: Setting value [%@] for key [%@]...", stringValue, aKey);
    const char *ckey = [aKey UTF8String];
    char *key = (char *)calloc(strlen(ckey), sizeof(char));
    if (key == NULL) {
        DLog(@"REDIS: SET : Error allocating memory for key.");
        return EXIT_FAILURE;
    }
    strcpy(key, ckey);
    const char *val = [stringValue UTF8String];
    char *value = (char *)calloc(strlen(val), sizeof(char));
    if (value == NULL) {
        DLog(@"REDIS: SET : Error allocating memory for value.");
        free(key);
        return EXIT_FAILURE;        
    }
    strcpy(value, val);
    redisReply *reply = NULL;
    redisContext *blockingContext = [self connect];
    if (blockingContext == NULL) {
        // Try again, otherwise leave
        blockingContext = [self connect];
        if (blockingContext == NULL) {
            DLog(@"REDIS: Unable to initialize synchronouse REDIS context.");
            free(key);
            free(value);
            return EXIT_FAILURE;
        }
    }
    void *response = redisCommand(blockingContext, "SET %s %b", key, value, strlen(value));
    if ([self processReply:blockingContext withReply:response andData:NULL]) {
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
        if (reply) {
            freeReplyObject(reply);
        }
        free(key);
        free(value);
        redisFree(blockingContext);
        return EXIT_FAILURE;
    }
    
    DLog(@"REDIS: SET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
    }
    free(key);
    free(value);
    redisFree(blockingContext);
    
    return EXIT_SUCCESS;
}

-(NSString *)stringValueForKey:(NSString *)aKey {
    DLog(@"REDIS: Getting value for key [%@]...", aKey);
    char *key = (char *)malloc((sizeof(char) * strlen([aKey UTF8String])));
    strcpy(key, [aKey UTF8String]);
    NSString *stringValue = nil;
    redisReply *reply = NULL;
    redisContext *blockingContext = [self connect];
    if (blockingContext == NULL) {
        // Try again, otherwise leave
        blockingContext = [self connect];
        if (blockingContext == NULL) {
            DLog(@"REDIS: Unable to initialize synchronouse REDIS context.");
            free(key);
            return nil;
        }
    }
    void *response = redisCommand(blockingContext, "GET %s", key);
    if ([self processReply:blockingContext withReply:response andData:NULL]) {
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
    DLog(@"REDIS: GET : Finishing...");
    if (reply) {
        freeReplyObject(reply);
        free(key);
    }
    redisFree(blockingContext);
    
    return stringValue;
}

-(NSUInteger)incrementKey:(NSString *)key {
    DLog(@"REDIS: Incrementing key [%@]...", key);
    NSUInteger incremented = UINT32_MAX;
    HandlerBundle bundle = NULL;
    redisAsyncContext *localAsyncCtx = [self connectAndDispatch];
    if (localAsyncCtx) {
        dispatch_semaphore_t incr = dispatch_semaphore_create(0);
        bundle = makeHandlerBundleC(nil, NULL, &incr);
        uint result = redisAsyncCommand(localAsyncCtx, rcIncr, bundle, "INCR %s", [key UTF8String]);
        if (result != REDIS_OK) {
            DLog(@"REDIS: Error buffering INCR command for this session : %s", localAsyncCtx->errstr);
            redisAsyncDisconnect(localAsyncCtx);
            free(bundle);
            dispatch_release(incr);
            return incremented;
        }
        dispatch_semaphore_wait(incr, DISPATCH_TIME_FOREVER);
        if (bundle) {
            incremented = bundle->int_data;
        }
        dispatch_release(incr);
    } else {
        DLog(@"REDIS: Unable to complete INCR.");
    }
    
    free(bundle); // IMP!
    return incremented;
}

-(NSUInteger)deleteKey:(NSString *)aKey {
    NSUInteger result = EXIT_FAILURE;
    DLog(@"REDIS: Deleting key [%@]...", aKey);
    const char *temp = [aKey UTF8String];
    char *key = (char *)calloc(strlen(temp), sizeof(char));
    if (key == NULL) {
        DLog(@"REDIS: DELETE : Unable to allocate memory for key.");
        return EXIT_FAILURE;
    }
    strcpy(key, temp);
    redisReply *reply = NULL;
    NSUInteger deleted = 0;
    redisContext *blockingContext = [self connect];
    if (blockingContext == NULL) {
        // Try again, otherwise leave
        blockingContext = [self connect];
        if (blockingContext == NULL) {
            DLog(@"REDIS: Unable to initialize synchronouse REDIS context.");
            free(key);
            return EXIT_FAILURE;
        }
    }
    void *response = redisCommand(blockingContext, "DEL %s", key);
    if ([self processReply:blockingContext withReply:response andData:NULL]) {
        reply = (redisReply *)response;
        if (reply->type == REDIS_REPLY_INTEGER) {
            deleted = reply->integer;
        } else {
            DLog(@"REDIS: DEL replied with (nil).");
            result = EXIT_FAILURE;
        }
        
    } else {
        DLog(@"REDIS: Error processing DEL.");
        result = EXIT_FAILURE;
    }
    
    DLog(@"REDIS: DEL : Finishing...");
    if (reply) {
        freeReplyObject(reply);
    }
    free(key);
    redisFree(blockingContext);
    
    if (deleted) {
        result = EXIT_SUCCESS;
    }
    
    return result;
}

- (void)dealloc {
    DLog(@"REDIS: Disconnecting from publish context...");
    
    if (!_asyncPubSessionContext->err) {
        redisAsyncDisconnect(_asyncPubSessionContext);
    }
    _asyncPubSessionContext = nil;
    
    //NSLog(@"REDIS: Deallocating blocking context...");
    //redisFree(_blockingContext);
    //_blockingContext = nil;
    
    [_dispatcher release];
    
    [super dealloc];
}

@end
