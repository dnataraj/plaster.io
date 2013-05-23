//
//  TSMessagingProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSMessagingProvider <NSObject>

- (void)publishObject:(NSString *)object toChannel:(NSString *)channel withCallback:(void (^)(id))callback;
- (void)publish:(const char *)bytes toChannel:(NSString *)channel withCallback:(void (^)(id))callback;
- (void)subscribeToChannels:(NSArray *)channels withCallback:(void (^)(id))callback andContext:(void *)context;

@end
