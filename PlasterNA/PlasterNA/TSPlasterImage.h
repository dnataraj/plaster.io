//
//  TSPlasterImage.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPlasterImage : NSObject <NSPasteboardReading, NSPasteboardWriting>

@property (copy) NSImage *image;

- (id)initWithImage:(NSImage *)anImage;

@end
