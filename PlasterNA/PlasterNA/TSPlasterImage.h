//
//  TSPlasterImage.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *PLASTER_IMAGE_UTI;

@interface TSPlasterImage : NSObject <NSPasteboardReading, NSPasteboardWriting>

@property (copy) NSImage *image;

- (id)initWithImage:(NSImage *)anImage;
- (NSData *)TIFFRepresentation;

@end
