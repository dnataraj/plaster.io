//
//  TSPasteboardPacket.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPasteboardPacket.h"

NSString * const PLASTER_UTI = @"com.trilobytesystems.plaster.uti";
NSString * const PLAIN_TEXT_UTI = @"public.utf8-plain-text";

@implementation TSPasteboardPacket {
    // The pasteboard item represented as a byte array (possibly null terminated?)
    char *__packet;
    NSString *_packet;
}

- (id)initWithTag:(NSString *)aTag andBytes:(const char *)bytes {
    self = [super init];
    if (self) {
        _tag = aTag;
        [self _setPacket:bytes];
        _packet = [[NSString alloc] initWithUTF8String:bytes];
        NSLog(@"Initialized packet with content [%@]", _packet);
    }
    
    return self;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    self = [super init];
    if (self) {
        NSLog(@"Initializing with property list %@", [propertyList class]);
        NSLog(@"and type %@", type);
        if ([type isEqualToString:PLASTER_UTI]) {
            _packet = [[NSString alloc] initWithPasteboardPropertyList:propertyList ofType:NSPasteboardTypeString];
            NSLog(@"Initialized packet after peer copy [%@]", _packet);
        }
    }
    return self;
}

- (void)_setPacket:(const char *)bytes {
    size_t length = sizeof(bytes);
    __packet = malloc(length);
    assert(__packet != NULL);
    int i = 0;
    while (i <= length) {
        __packet[i] = bytes[i];
        i++;
    }
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    static NSArray *writeableTypes = nil;
    if (!writeableTypes) {
        writeableTypes = [[NSArray alloc] initWithObjects:PLASTER_UTI, NSPasteboardTypeString, PLAIN_TEXT_UTI, nil];
    }
    NSLog(@"Returning writeable types...");
    return writeableTypes;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:PLASTER_UTI]) {
        NSLog(@"Returning packet for type [%@]", PLASTER_UTI);
        return _packet;
    }
    if ([type isEqualToString:NSPasteboardTypeString]) {
        NSLog(@"Returning packet for type [%@]", NSPasteboardTypeString);
        return _packet;
    }
    if ([type isEqualToString:PLAIN_TEXT_UTI]) {
        NSLog(@"Returning packet for type [%@]", PLAIN_TEXT_UTI);
        return _packet;
    }
    
    return nil;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    static NSArray *readableTypes = nil;
    if (!readableTypes) {
        readableTypes = [[NSArray alloc] initWithObjects:PLASTER_UTI, NSPasteboardTypeString, PLAIN_TEXT_UTI, nil];
    }
    NSLog(@"Returning readable types...");
    return readableTypes;
}


/*
+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    NSLog(@"Requesting reading options for type [%@]", type);
    if ([type isEqualToString:PLASTER_UTI]) {
        return NSPasteboardReadingAsData;
    }
    
    return NSPasteboardReadingAsString;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    NSLog(@"Providing data for pasteboard..");
    if ([type compare:NSPasteboardTypeString] == NSOrderedSame) {
        NSData *data = [NSData dataWithBytes:_packet length:strlen(_packet)];
        [pasteboard setData:data forType:NSPasteboardTypeString];
    }
}
*/

@end
