//
//  TSLPlasterProfile.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/5/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterProfile.h"
#import "TSLPlasterController.h"
#import "TSLPlasterGlobals.h"

@interface TSLPlasterProfile () {
    TSLPlasterController *_plasterController;
}


@end

@implementation TSLPlasterProfile

- (id)initWithProfile:(NSDictionary *)profile sessionKey:(NSString *)key provider:(id<TSMessagingProvider, TSDataStoreProvider>)provider {
    self = [super init];
    if (self) {
        _profile = [profile copy];
        _plasterController = [[TSLPlasterController alloc] initWithPasteboard:[UIPasteboard generalPasteboard] provider:provider];
        _sessionKey = [key copy];
        
        [_plasterController setSessionKey:key];
        [_plasterController setAlias:[[UIDevice currentDevice] name]];
        [_plasterController setSessionProfile:_profile];
        
        _plasterBgTask = UIBackgroundTaskInvalid;
        
    }
    
    return self;
}

- (TSLPlasterState)state {
    if ([_plasterController isRunning]) {
        return TSLPlasterRunning;
    }
    
    return TSLPlasterStopped;
}

- (NSArray *)peers {
    return [_plasterController connectedPeers];
}

- (NSUInteger)controlPlaster:(TSLPlasterControls)action {
    UIApplication *application = [UIApplication sharedApplication];    
    __block TSLPlasterController *__plasterController = _plasterController;
    __block UIBackgroundTaskIdentifier __plasterBgTask = self.plasterBgTask;
    
    if (action == TSLPlasterStart) {
        // if the controller is running, log this and return.
        if ([self state] == TSLPlasterRunning) {
            DLog(@"Plaster Controller already running. Ignoring request to start.");
            return EXIT_SUCCESS;
        }
        
        __plasterBgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            DLog(@"Plaster background monitor was stiatched. Cleaning up...");
            [__plasterController stop];
            __plasterController = nil;
            DLog(@"Ending plaster monitor background task registration.");
            [application endBackgroundTask:__plasterBgTask];
            __plasterBgTask = UIBackgroundTaskInvalid;
        }];
        
        if (__plasterBgTask == UIBackgroundTaskInvalid) {
            DLog(@"iOS Kernel refuses to create plaster background monitor. Stiatched.");
            return EXIT_SUCCESS;
        }
        
        return [__plasterController start];
    } else if (action == TSLPlasterStop) {
        // if the controller was not running, log this and return.
        if ([self state] == TSLPlasterStopped) {
            DLog(@"Plaster Controller already stopped. Ignoring request to start.");
            return EXIT_SUCCESS;
        }
        
        // Create a temporary background task "registration" for stopping (in case this takes longer than expected)
        __block UIBackgroundTaskIdentifier __plasterStopBgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            DLog(@"Plaster background monitor was stiatched. Cleaning up...");
            // Try stop again
            [__plasterController stop];
            __plasterController = nil;
            DLog(@"Ending plaster monitor background task registration.");
            [application endBackgroundTask:__plasterStopBgTask];
            __plasterStopBgTask = UIBackgroundTaskInvalid;
        }];
        [_plasterController stop];
        
        [application endBackgroundTask:__plasterStopBgTask];
        
        // if the controller stopped, end the corresponding bg task registration and set it to be invalid.
        if (__plasterBgTask != UIBackgroundTaskInvalid) {
            DLog(@"Ending plaster monitor background task registration.");
            [application endBackgroundTask:__plasterBgTask];
            __plasterBgTask = UIBackgroundTaskInvalid;
        }
        
    }
    
    return EXIT_SUCCESS;
}

- (NSString *)name {
    return [self.profile objectForKey:TSPlasterProfileName];
}

- (void)dealloc {
    if ([_plasterController isRunning]) {
        DLog(@"Plaster controller was running, stopping now...");
        [_plasterController stop];
    }
    [_plasterController release];
    [_sessionKey release];
    [_profile release];
    [super dealloc];
}

@end
