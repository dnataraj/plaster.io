//
//  TSPlasterImage.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPlasterImage.h"

NSString *PLASTER_IMAGE_UTI = @"com.trilobytesystems.plaster.image.uti";

@implementation TSPlasterImage

- (id)initWithImage:(NSImage *)anImage {
    self = [super init];
    if (self) {
        self.image = anImage;
    }
    
    return self;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    self = [super init];
    if (self) {
        DLog(@"PACKET: Initializing with property list %@", [propertyList class]);
        DLog(@"PACKET: and type %@", type);
        if ([type isEqualToString:PLASTER_IMAGE_UTI]) {
            self.image = [[[NSImage alloc] initWithPasteboardPropertyList:propertyList ofType:NSPasteboardTypeTIFF] autorelease];
        } else {
            self.image = [[[NSImage alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
            
        }
        
    }
    return self;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *readables = [NSMutableArray arrayWithArray:[NSImage readableTypesForPasteboard:pasteboard]];
    [readables addObject:PLASTER_IMAGE_UTI];
    
    return readables;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *writables = [NSMutableArray arrayWithArray:[self.image writableTypesForPasteboard:pasteboard]];
    [writables addObject:PLASTER_IMAGE_UTI];
    
    return writables;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:PLASTER_IMAGE_UTI]) {
        return [self.image pasteboardPropertyListForType:NSPasteboardTypeTIFF];
    }
    
    return [self.image pasteboardPropertyListForType:type];
}

- (NSData *)TIFFRepresentation {
    return [self.image TIFFRepresentation];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Packet with [%f]h and [%f]w.", [self.image size].height, [self.image size].width];
}

- (void)dealloc {
    [_image release];
    [super dealloc];
}

@end
