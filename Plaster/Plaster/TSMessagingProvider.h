//
//  TSMessagingProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^mpCallback)(id reply, id data);

@protocol TSMessagingProvider <NSObject>

- (void)publishObject:(NSString *)object toChannel:(NSString *)channel;
- (void)publish:(const char *)bytes toChannel:(NSString *)channel;
- (void)subscribeToChannels:(NSSet *)channels withCallback:(mpCallback)callback andContext:(id)context;

@end
