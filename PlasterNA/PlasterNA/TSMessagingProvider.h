//
//  TSMessagingProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^mpCallback)(id reply, id data);
typedef void (*mpCallbackC)(char *reply, void *data);

@protocol TSMessagingProvider <NSObject>

- (void)publishObject:(NSString *)object toChannel:(NSString *)channel;
- (void)publish:(const char *)bytes toChannel:(NSString *)channel;
- (NSString *)subscribeToChannels:(NSArray *)channels withCallback:(mpCallbackC)callback andContext:(void *)context;
- (void)unsubscribe:(NSString *)subscriptionID;
- (void)unsubscribeAll;

@end
