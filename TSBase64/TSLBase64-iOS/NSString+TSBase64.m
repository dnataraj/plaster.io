//
//  NSString+TSBase64.m
//  TSBase64
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "NSString+TSBase64.h"
#import "TSBase64.h"

@implementation NSString (TSBase64)

- (NSString *)base64String {
    @autoreleasepool {
        const char * string = [self cStringUsingEncoding:NSUTF8StringEncoding];
        size_t len = strlen(string);
        size_t size = base64_encode(string, len, NULL, 0);
        char * newstring = (char *)malloc(size + 1);
        memset(newstring, 0, size + 1);
        len = base64_encode(string, len, newstring, size);
        NSString * nsstr = [NSString stringWithCString:newstring encoding:NSUTF8StringEncoding];
        free(newstring);
        newstring = NULL;
        return nsstr;
    }
}

- (NSData *)dataFromBase64 {
    @autoreleasepool {
        NSData * fromData = [self dataUsingEncoding:NSUTF8StringEncoding];
        size_t len = base64_decode([fromData bytes], [fromData length], NULL, 0);
        NSMutableData * data = [[NSMutableData alloc] initWithLength:len];
        len = base64_decode([fromData bytes], [fromData length], [data mutableBytes], [data length]);
        NSData * d = [data copy];
        data = nil;
        return d;
    }
}
@end
