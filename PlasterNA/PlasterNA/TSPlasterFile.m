//
//  TSPlasterFile.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 7/16/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPlasterFile.h"

NSString *PLASTER_FILE_UTI = @"com.trilobytesystems.plaster.file.uti";

@implementation TSPlasterFile

- (id)initWithURL:(NSURL *)anURL {
    self = [super init];
    if (self) {
        _fileURL = [anURL retain];
    }
    
    return self;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    self = [super init];
    if (self) {
        DLog(@"PACKET: Initializing with property list %@", [propertyList class]);
        DLog(@"PACKET: and type %@", type);
        if ([type isEqualToString:PLASTER_FILE_UTI]) {
            _fileURL = [[[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:NSFilenamesPboardType] autorelease];
        } else {
            _fileURL = [[[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
            
        }
        
    }
    return self;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *readables = [NSMutableArray arrayWithArray:[NSURL readableTypesForPasteboard:pasteboard]];
    [readables addObject:PLASTER_FILE_UTI];
    
    return readables;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *writables = [NSMutableArray arrayWithArray:[_fileURL writableTypesForPasteboard:pasteboard]];
    [writables addObject:PLASTER_FILE_UTI];
    
    return writables;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:PLASTER_FILE_UTI]) {
        return [_fileURL pasteboardPropertyListForType:NSFilenamesPboardType];
    }
    
    return [_fileURL pasteboardPropertyListForType:type];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Packet with file URL : %@", _fileURL];
}

- (void)dealloc {
    [_fileURL release];
    [super dealloc];
}

@end
