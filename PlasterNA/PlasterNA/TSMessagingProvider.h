//
//  TSMessagingProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSPlasterHandler;

typedef void (*mpCallback)(char *reply, void *data);

@protocol TSMessagingProvider <NSObject>

- (void)publishObject:(NSString *)object toChannel:(NSString *)channel;
- (void)publish:(const char *)bytes toChannel:(NSString *)channel;
- (NSString *)subscribeToChannels:(NSArray *)channels options:(NSDictionary *)someOptions;
- (void)unsubscribeAll;

@end
