//
//  TSEventDispatcher.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSEventDispatcher.h"

#define DEFAULT_TIMER_LEEWAY_PERCENTAGE 30

typedef struct {
    redisAsyncContext *context;
    BOOL _isReading, _isWriting;
    dispatch_source_t _readEvent, _writeEvent;
} tsDispatchContext;

void redisRead(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (!dc->_isReading) {
        dc->_isReading = YES;
        dispatch_resume(dc->_readEvent);
    }
}

void redisDeleteRead(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (dc->_isReading) {
        dc->_isReading = NO;
        dispatch_suspend(dc->_readEvent);
    }
}

void redisWrite(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (!dc->_isWriting) {
        dc->_isWriting = YES;
        dispatch_resume(dc->_writeEvent);
    }
}

void redisDeleteWrite(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    if (dc->_isWriting) {
        dc->_isWriting = NO;
        dispatch_suspend(dc->_writeEvent);
    }
}

void redisClean(void *privateData) {
    tsDispatchContext *dc = (tsDispatchContext *)privateData;
    
    if (dc->_readEvent != NULL && dispatch_source_testcancel(dc->_readEvent) == 0) {
        redisRead(privateData);
        dispatch_source_cancel(dc->_readEvent);
        dispatch_release(dc->_readEvent);
    }
    
    if (dc->_writeEvent != NULL && dispatch_source_testcancel(dc->_writeEvent) == 0) {
        redisWrite(privateData);
        dispatch_source_cancel(dc->_writeEvent);
        dispatch_release(dc->_writeEvent);
    }
    
    free(dc);
}

/*
int redisAttachAndDispatch(redisAsyncContext *asyncContext, dispatch_queue_t queue) {
    redisContext *redisCtx = &(asyncContext->c);
    
    if (asyncContext->ev.data != NULL) {
        return REDIS_ERR;        
    }
    
    // Initialize and install read/write events
    dispatch_source_t readEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, redisCtx->fd, 0, queue);
    if (readEvent == NULL) {
        return REDIS_ERR_IO;        
    }
    dispatch_source_set_event_handler(readEvent, ^{
        redisAsyncHandleRead(asyncContext);
    });
    
    dispatch_source_t writeEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, redisCtx->fd, 0, queue);
    if (writeEvent == NULL) {
        return REDIS_ERR_IO;        
    }
    dispatch_source_set_event_handler(writeEvent, ^{
        redisAsyncHandleWrite(asyncContext);
    });
    
    // Create container for context and r/w events
    tsDispatchContext *dc = (tsDispatchContext *)malloc(sizeof(*dc));
    dc->context = asyncContext;
    dc->_isReading = dc->_isWriting = 0;
    
    // Register functions to start/stop listening for events
    asyncContext->ev.addRead = redisRead;
    asyncContext->ev.delRead = redisDeleteRead;
    asyncContext->ev.addWrite = redisWrite;
    asyncContext->ev.delWrite = redisDeleteWrite;
    asyncContext->ev.cleanup = redisClean;
    asyncContext->ev.data = dc;  // Do we need this?
    dc->_readEvent = readEvent;
    dc->_writeEvent = writeEvent;
    
    return REDIS_OK;
}
*/

@implementation TSEventDispatcher {
    dispatch_queue_t _queue;
    NSMutableDictionary *_timers;
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"Obtaining event dispatcher queue...");
        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _timers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (int)dispatchWithContext:(redisAsyncContext *)asyncContext {
    redisContext *redisCtx = &(asyncContext->c);
    
    if (asyncContext->ev.data != NULL) {
        return REDIS_ERR;
    }
    
    // Initialize and install read/write events
    dispatch_source_t readEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, redisCtx->fd, 0, _queue);
    if (readEvent == NULL) {
        return REDIS_ERR_IO;
    }
    dispatch_source_set_event_handler(readEvent, ^{
        redisAsyncHandleRead(asyncContext);
    });
    
    dispatch_source_t writeEvent = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, redisCtx->fd, 0, _queue);
    if (writeEvent == NULL) {
        return REDIS_ERR_IO;
    }
    dispatch_source_set_event_handler(writeEvent, ^{
        redisAsyncHandleWrite(asyncContext);
    });
    
    // Create container for context and r/w events
    tsDispatchContext *dc = (tsDispatchContext *)malloc(sizeof(*dc));
    dc->context = asyncContext;
    dc->_isReading = dc->_isWriting = 0;
    
    // Register functions to start/stop listening for events
    asyncContext->ev.addRead = redisRead;
    asyncContext->ev.delRead = redisDeleteRead;
    asyncContext->ev.addWrite = redisWrite;
    asyncContext->ev.delWrite = redisDeleteWrite;
    asyncContext->ev.cleanup = redisClean;
    asyncContext->ev.data = dc;  // Do we need this?
    dc->_readEvent = readEvent;
    dc->_writeEvent = writeEvent;
    
    return REDIS_OK;    
}

- (void)dispatchTask:(NSString *)taskName WithPeriod:(uint64_t)interval andHandler:(void (^)(void))handler {
    uint64_t leeway = ((uint64_t)(DEFAULT_TIMER_LEEWAY_PERCENTAGE / 100)) * interval;
    dispatch_source_t timer = [self createTimerWithInterval:interval andLeeway:leeway];
    dispatch_source_set_event_handler(timer, handler);
    dispatch_resume(timer);
    NSLog(@"Adding timer to list...");
    [_timers setObject:timer forKey:taskName];
}

- (void)stopTask:(NSString *)taskName {
    dispatch_source_t timer = [_timers objectForKey:taskName];
    if (!timer) {
        NSLog(@"No task with name %@ is availble.", taskName);
        return;
    }
    NSLog(@"Cancelling task : %@", taskName);
    dispatch_source_cancel(timer);
    [_timers removeObjectForKey:taskName];
    timer = nil;
}

- (dispatch_source_t) createTimerWithInterval:(uint64_t)interval andLeeway:(uint64_t)leeway {
    NSLog(@"Creating a dispatch timer...");
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
    }
    
    return timer;
}

@end
