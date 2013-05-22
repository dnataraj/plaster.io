//
//  TSPasteboardPacket.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPasteboardPacket : NSObject <NSPasteboardWriting, NSPasteboardReading>

@property (readwrite, copy) NSString *tag;

- (id)initWithTag:(NSString *)aTag andBytes:(const char *)bytes;
- (id)initWithTag:(NSString *)aTag andString:(NSString *)aString;

@end
