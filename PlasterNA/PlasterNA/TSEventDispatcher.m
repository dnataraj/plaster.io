//
//  TSEventDispatcher.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSEventDispatcher.h"

#define DEFAULT_TIMER_LEEWAY_PERCENTAGE 30

typedef struct _tsDispatchContext {
    redisAsyncContext *context;
    BOOL _isReading, _isWriting;
    dispatch_source_t _readEvent, _writeEvent;
} tsDispatchContext;

void redisRead(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (!dc->_isReading) {
        if (dc->_readEvent) {
            dc->_isReading = YES;
            dispatch_resume(dc->_readEvent);
        }
    }
}

void redisDeleteRead(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (dc->_isReading) {
        if (dc->_readEvent) {
            dc->_isReading = NO;
            dispatch_suspend(dc->_readEvent);
        }
    }
}

void redisWrite(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (!dc->_isWriting) {
        if (dc->_writeEvent) {
            dc->_isWriting = YES;
            dispatch_resume(dc->_writeEvent);
        }
    }
}

void redisDeleteWrite(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (dc->_isWriting) {
        if (dc->_writeEvent) {
            dc->_isWriting = NO;
            dispatch_suspend(dc->_writeEvent);            
        }
    }
}

void redisClean(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    
    if (dc->_readEvent != NULL && dispatch_source_testcancel(dc->_readEvent) == 0) {
        redisRead(privateData);
        dispatch_source_cancel(dc->_readEvent);
        dispatch_release(dc->_readEvent);
        dc->_readEvent = nil;
    }
    
    if (dc->_writeEvent != NULL && dispatch_source_testcancel(dc->_writeEvent) == 0) {
        redisWrite(privateData);
        dispatch_source_cancel(dc->_writeEvent);
        dispatch_release(dc->_writeEvent);
        dc->_writeEvent = nil;
    }
    
    free(dc);
}

@implementation TSEventDispatcher {
    dispatch_queue_t _queue;
    NSMutableDictionary *_timers;
}

- (id)init {
    self = [super init];
    if (self) {
        //_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        _queue = dispatch_queue_create("PLASTER", DISPATCH_QUEUE_CONCURRENT);
        _timers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (uint)dispatchWithContext:(redisAsyncContext *)asyncContext {
    redisContext *redisCtx = &(asyncContext->c);
    
    if (asyncContext->ev.data != NULL) {
        return REDIS_ERR;
    }
    
    // Initialize and install read/write events
    dispatch_source_t readEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, redisCtx->fd, 0, _queue);
    if (readEvent == NULL) {
        return REDIS_ERR_IO;
    }
    
    //dispatch_retain(readEvent);
    dispatch_source_set_event_handler(readEvent, ^{
        redisAsyncHandleRead(asyncContext);
        //dispatch_release(readEvent);
    });
    
    dispatch_source_t writeEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, redisCtx->fd, 0, _queue);
    if (writeEvent == NULL) {
        return REDIS_ERR_IO;
    }
    
    dispatch_source_set_event_handler(writeEvent, ^{
        redisAsyncHandleWrite(asyncContext);
    });
    
    // Create container for context and r/w events
    tsDispatchContext *dc = (tsDispatchContext *)malloc(sizeof(struct _tsDispatchContext));
    dc->context = asyncContext;
    dc->_isReading = dc->_isWriting = 0;
    dc->_readEvent = readEvent;
    dc->_writeEvent = writeEvent;
    
    // Register functions to start/stop listening for events
    asyncContext->ev.addRead = redisRead;
    asyncContext->ev.delRead = redisDeleteRead;
    asyncContext->ev.addWrite = redisWrite;
    asyncContext->ev.delWrite = redisDeleteWrite;
    asyncContext->ev.cleanup = redisClean;
    asyncContext->ev.data = dc;  // Do we need this?
    
    return REDIS_OK;    
}

- (uint)dispatchTask:(NSString *)taskName WithPeriod:(uint64_t)interval andHandler:(void (^)(void))handler {
    if (!taskName || !handler) {
        return TS_DISPATCH_ERR;
    }
    if ([_timers objectForKey:taskName]) {
        printf("DISPATCHER: Timer already exists, stop it first.\n");
        return TS_DISPATCH_ERR;
    }
    uint64_t leeway = ((uint64_t)(DEFAULT_TIMER_LEEWAY_PERCENTAGE / 100)) * interval;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, handler);
        dispatch_resume(timer);
        printf("DISPATCHER: Adding timer to list...\n");
        [_timers setObject:timer forKey:taskName];
        return TS_DISPATCH_OK;
    }
    
    return TS_DISPATCH_ERR;
}

- (uint)dispatchTask:(NSString *)taskName WithPeriod:(uint64_t)interval andController:(TSPlasterController *)controller {
    if (!taskName || !controller) {
        return TS_DISPATCH_ERR;
    }
    if ([_timers objectForKey:taskName]) {
        printf("DISPATCHER: Timer already exists, stop it first.\n");
        return TS_DISPATCH_ERR;
    }
    uint64_t leeway = ((uint64_t)(DEFAULT_TIMER_LEEWAY_PERCENTAGE / 100)) * interval;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
        __block id unretained_cont = controller;
        dispatch_source_set_event_handler(timer, ^{
            [unretained_cont onTimer];
        });
        dispatch_resume(timer);
        printf("DISPATCHER: Adding timer to list...\n");
        [_timers setObject:timer forKey:taskName];
        return TS_DISPATCH_OK;
    }
    
    return TS_DISPATCH_ERR;
    
}

- (uint)stopTask:(NSString *)taskName {
    dispatch_source_t timer = [_timers objectForKey:taskName];
    if (!timer) {
        printf("DISPATCHER: No task with name %s is availble.\n", [taskName UTF8String]);
        return TS_DISPATCH_ERR;
    }
    printf("DISPATCHER: Cancelling task : %s\n", [taskName UTF8String]);
    dispatch_source_cancel(timer);
    dispatch_release(timer);
    [_timers removeObjectForKey:taskName];
    timer = nil;
    return TS_DISPATCH_OK;
}

- (void)dealloc {
    [_timers release];
    _timers = nil;
    [super dealloc];
}

@end
