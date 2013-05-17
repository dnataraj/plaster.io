//
//  TSEventDispatcher.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "hiredis.h"
#import "async.h"

void redisRead(void *privateData);
void redisDeleteRead(void *privateData);
void redisWrite(void *privateData);
void redisDeleteWrite(void *privateData);
void redisClean(void *privateData);
//int redisAttachAndDispatch(redisAsyncContext *asyncContext, dispatch_queue_t queue);

@interface TSEventDispatcher : NSObject

- (int)dispatchWithContext:(redisAsyncContext *)asyncContext;
- (void)dispatchTask:(NSString *)taskName WithPeriod:(uint64_t)interval andHandler:(void (^)(void))handler;
- (void)stopTask:(NSString *)taskName;
                                                               
@end
