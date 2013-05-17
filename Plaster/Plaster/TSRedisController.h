//
//  TSRedisController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/15/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSEventDispatcher;

@interface TSRedisController : NSObject

- (id)initWithDispatcher:(TSEventDispatcher *)dispatcher;

@end
