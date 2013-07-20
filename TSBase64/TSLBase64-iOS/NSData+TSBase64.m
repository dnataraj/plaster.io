//
//  NSData+TSBase64.m
//  TSBase64
//
//  Created by Deepak Natarajan on 6/16/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "NSData+TSBase64.h"
#import "TSBase64.h"

@implementation NSData (TSBase64)

- (NSString *)base64String {
    size_t len = base64_encode(self.bytes, self.length, NULL, 0);
    void * stringData = malloc(len);
    len = base64_encode(self.bytes, self.length, stringData, len);
    NSString * s = [NSString stringWithUTF8String:stringData];
    free(stringData);
    return s;
}

@end
