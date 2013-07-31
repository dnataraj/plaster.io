//
//  TSPlasterImage.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterImage.h"

NSString *PLASTER_IMAGE_UTI = @"com.trilobytesystems.plaster.ios.image.uti";

@implementation TSLPlasterImage

- (id)initWithImage:(UIImage *)anImage {
    self = [super init];
    if (self) {
        self.image = anImage;
    }
    
    return self;
}

- (NSData *)PNGRepresentation {
    return UIImagePNGRepresentation(self.image);
}

- (NSData *)JPEGRepresentation {
    return UIImageJPEGRepresentation(self.image, 0.75);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Packet with [%f]h and [%f]w.", [self.image size].height, [self.image size].width];
}

- (void)dealloc {
    [_image release];
    [super dealloc];
}

@end
