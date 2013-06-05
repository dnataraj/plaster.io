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
}

- (id)init {
    self = [super init];
    if (self) {
        _tag = nil;
        _packet = nil;
        [self _setPacket:NULL];
    }
    
    return self;
}

- (id)initWithTag:(NSString *)aTag bytes:(const char *)bytes {
    self = [self init];
    if (self) {
        _tag = aTag;
        [self _setPacket:bytes];
        _packet = [[NSString alloc] initWithUTF8String:bytes];
    }
    
    return self;
}

- (id)initWithTag:(NSString *)aTag string:(NSString *)aString {
    self = [self init];
    if (self) {
        _tag = aTag;
        _packet = [aString copy];
    }
    
    return self;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    self = [self init];
    if (self) {
        NSLog(@"PACKET: Initializing with property list %@", [propertyList class]);
        NSLog(@"PACKET: and type %@", type);
        if ([type isEqualToString:PLASTER_UTI]) {
            _packet = [[NSString alloc] initWithPasteboardPropertyList:propertyList ofType:NSPasteboardTypeString];
            NSLog(@"PACKET: Initialized packet after peer copy [%@]", _packet);
        }
    }
    return self;
}

- (void)_setPacket:(const char *)bytes {
    if (bytes) {
        size_t length = sizeof(bytes);
        __packet = malloc(length);
        assert(__packet != NULL);
        int i = 0;
        while (i <= length) {
            __packet[i] = bytes[i];
            i++;
        }        
    }
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    static NSArray *writeableTypes = nil;
    if (!writeableTypes) {
        writeableTypes = [[NSArray alloc] initWithObjects:PLASTER_UTI, NSPasteboardTypeString, PLAIN_TEXT_UTI, nil];
    }
    return [writeableTypes autorelease];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:PLASTER_UTI]) {
        NSLog(@"PACKET: Returning packet for type [%@]", PLASTER_UTI);
        return _packet;
    }
    if ([type isEqualToString:NSPasteboardTypeString]) {
        NSLog(@"PACKET: Returning packet for type [%@]", NSPasteboardTypeString);
        return _packet;
    }
    if ([type isEqualToString:PLAIN_TEXT_UTI]) {
        NSLog(@"PACKET: Returning packet for type [%@]", PLAIN_TEXT_UTI);
        return _packet;
    }
    
    return nil;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    static NSArray *readableTypes = nil;
    if (!readableTypes) {
        readableTypes = [[NSArray alloc] initWithObjects:PLASTER_UTI, NSPasteboardTypeString, PLAIN_TEXT_UTI, nil];
    }
    return [readableTypes autorelease];
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

- (NSString *)description {
    if ([[self tag] isEqualToString:@"plaster-packet-string"]) {
        return [NSString stringWithFormat:@"Packet [%@]", _packet];
    }
    
    return @"PACKET: Not Ready.";
}

- (void)dealloc {
    free(__packet);
    [_packet release];
    [super dealloc];
}

@end
