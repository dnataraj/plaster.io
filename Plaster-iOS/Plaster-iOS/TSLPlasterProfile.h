//
//  TSLPlasterProfile.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/5/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessagingProvider.h"
#import "TSDataStoreProvider.h"

@class TSLPlasterController;

typedef NS_ENUM(NSUInteger, TSLPlasterControls) {
    TSLPlasterStart,
    TSLPlasterStop
};

typedef NS_ENUM(NSUInteger, TSLPlasterState) {
    TSLPlasterRunning,
    TSLPlasterStopped
};

@interface TSLPlasterProfile : NSObject

//@property (retain, readonly, nonatomic) TSLPlasterController *plasterController;
@property (nonatomic) UIBackgroundTaskIdentifier plasterBgTask;
@property (copy, readonly, nonatomic) NSString *sessionKey;
@property (copy, readonly, nonatomic) NSDictionary *profile;

- (id)initWithProfile:(NSDictionary *)profile sessionKey:(NSString *)key provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider;

- (TSLPlasterState)state;
- (NSUInteger)controlPlaster:(TSLPlasterControls)action;
- (NSString *)name;
- (NSArray *)peers;

@end
