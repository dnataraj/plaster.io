//
//  TSPlasterString.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *PLASTER_STRING_UTI;

@interface TSPlasterString : NSObject <NSPasteboardReading, NSPasteboardWriting>

@property (copy) NSString *string;

- (id)initWithString:(NSString *)aString;
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding;
- (BOOL)hasPrefix:(NSString *)aString;
- (NSString *)substringFromIndex:(NSUInteger)anIndex;

@end
