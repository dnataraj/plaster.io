//
//  TSPlasterImage.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const PLASTER_IMAGE_UTI;

@interface TSLPlasterImage : NSObject

@property (copy) UIImage *image;

- (id)initWithImage:(UIImage *)anImage;
- (NSData *)PNGRepresentation;
- (NSData *)JPEGRepresentation;

@end
