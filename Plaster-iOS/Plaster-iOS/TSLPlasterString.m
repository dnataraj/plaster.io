//
//  TSPlasterString.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterString.h"

NSString *PLASTER_STRING_UTI = @"com.trilobytesystems.plaster.ios.string.uti";

@implementation TSLPlasterString

- (id)initWithString:(NSString *)aString {
    self = [super init];
    if (self) {
        self.string = aString;
    }
    
    return self;
}

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding {
    return [self.string dataUsingEncoding:encoding];
}

- (BOOL)hasPrefix:(NSString *)aString {
    return [self.string hasPrefix:aString];
}

- (NSString *)substringFromIndex:(NSUInteger)anIndex {
    return [self.string substringFromIndex:anIndex];
}

- (NSString *)description {
        return [NSString stringWithFormat:@"Packet with [%ld] characters.", (unsigned long)[self.string length]];
}

- (void)dealloc {
    [_string release];
    [super dealloc];
}

@end
