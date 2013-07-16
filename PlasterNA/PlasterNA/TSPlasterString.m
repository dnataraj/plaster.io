//
//  TSPlasterString.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/17/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPlasterString.h"

NSString *PLASTER_STRING_UTI = @"com.trilobytesystems.plaster.string.uti";

@implementation TSPlasterString

- (id)initWithString:(NSString *)aString {
    self = [super init];
    if (self) {
        self.string = aString;
    }
    
    return self;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    self = [super init];
    if (self) {
        DLog(@"PACKET: Initializing with property list %@", [propertyList class]);
        DLog(@"PACKET: and type %@", type);
        if ([type isEqualToString:PLASTER_STRING_UTI]) {
            self.string = [[[NSString alloc] initWithPasteboardPropertyList:propertyList ofType:NSPasteboardTypeString] autorelease];
        } else {
            self.string = [[[NSString alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
            
        }
        
    }
    return self;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *readables = [NSMutableArray arrayWithArray:[NSString readableTypesForPasteboard:pasteboard]];
    [readables addObject:PLASTER_STRING_UTI];
    
    return readables;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *writables = [NSMutableArray arrayWithArray:[self.string writableTypesForPasteboard:pasteboard]];
    [writables addObject:PLASTER_STRING_UTI];
    
    return writables;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:PLASTER_STRING_UTI]) {
        return [self.string pasteboardPropertyListForType:NSPasteboardTypeString];
    }
    
    return [self.string pasteboardPropertyListForType:type];
}

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding {
    return [self.string dataUsingEncoding:encoding];
}

- (BOOL)hasPrefix:(NSString *)aString {
    return [self.string hasPrefix:aString];
}

- (NSString *)substringFromIndex:(NSUInteger)anIndex {
    return [self.string substringFromIndex:anIndex];
}

- (NSString *)description {
        return [NSString stringWithFormat:@"Packet with [%ld] characters.", (unsigned long)[self.string length]];
}

- (void)dealloc {
    [_string release];
    [super dealloc];
}

@end
