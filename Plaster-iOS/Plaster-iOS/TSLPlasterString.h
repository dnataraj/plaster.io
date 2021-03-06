//
//  TSPlasterString.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const PLASTER_STRING_UTI;
 
@interface TSLPlasterString : NSObject

@property (copy) NSString *string;

- (id)initWithString:(NSString *)aString;
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding;
- (BOOL)getCString:(char *)buffer maxLength:(NSUInteger)maxBufferCount encoding:(NSStringEncoding)encoding;
- (BOOL)hasPrefix:(NSString *)aString;
- (NSString *)substringFromIndex:(NSUInteger)anIndex;

@end
