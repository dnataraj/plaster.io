//
//  TSAsyncRedisContext.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/28/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRedisController.h"
#import "async.h"

@interface TSRedisSubscriptionContext : NSObject

@property (readwrite, retain) NSString *channels;

- (id)initWithRedisContext:(redisAsyncContext *)redisContext channels:(NSString *)channels bundle:(HandlerBundle)bundle;
- (id)initWithRedisContext:(redisAsyncContext *)redisContext;

- (redisAsyncContext *)context;
- (void)freeBundle;

@end
