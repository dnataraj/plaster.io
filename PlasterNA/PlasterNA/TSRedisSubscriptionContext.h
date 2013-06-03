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

@property (readwrite, copy) NSArray *channels;

- (id)initWithRedisContext:(redisAsyncContext *)redisContext channels:(NSArray *)channels bundle:(HandlerBundle)bundle;

- (redisAsyncContext *)context;
- (void)freeBundle;

@end
