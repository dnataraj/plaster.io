//
//  TSPlasterString.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPlasterString : NSObject <NSPasteboardReading, NSPasteboardWriting>

@property (copy) NSString *string;

- (id)initWithString:(NSString *)aString;

@end
