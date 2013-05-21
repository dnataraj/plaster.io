//
//  NSString+TSPasteboardString.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/18/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "NSString+TSPasteboardString.h"
#import <objc/message.h>

NSString * const peerCopyKey = @"TS_PEER_COPY";

@implementation NSString (TSPasteboardString)

//@dynamic peerCopy;

- (void)setPeerCopy:(NSNumber *)aPeerCopy {
    NSLog(@"Setting peerCopy to [%@]", aPeerCopy);
    objc_setAssociatedObject(self, (__bridge const void *)(peerCopyKey), aPeerCopy, OBJC_ASSOCIATION_COPY);
}

- (NSNumber *)peerCopy {
    NSLog(@"Returning peerCopy...");
    return objc_getAssociatedObject(self, (__bridge const void *)(peerCopyKey));
}


@end
