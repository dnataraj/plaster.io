//
//  TSMessagingProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (*mpCallback)(char *reply, void *data);

@protocol TSMessagingProvider <NSObject>

- (NSUInteger)publishObject:(NSString *)object channel:(NSString *)channel options:(NSDictionary *)options;
- (NSUInteger)publish:(const char *)bytes channel:(NSString *)channel options:(NSDictionary *)options;
- (NSUInteger)subscribeToChannels:(NSArray *)channels options:(NSDictionary *)someOptions;
- (NSUInteger)subscribeToChannel:(NSString *)channel options:(NSDictionary *)someOptions;
- (void)unsubscribeAll;

@end
