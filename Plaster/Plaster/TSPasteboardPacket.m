//
//  TSPasteboardPacket.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPasteboardPacket.h"

@implementation TSPasteboardPacket {
    // The pasteboard item represented as a byte array (possibly null terminated?)
    char *_packet;
}

- (id)initWithTag:(NSString *)aTag andBytes:(char *)bytes {
    self = [super init];
    if (self) {
        _tag = aTag;
        [self _setPacket:bytes];
    }
    
    return self;
}

- (void)_setPacket:(char *)bytes {
    size_t length = sizeof(bytes);
    _packet = malloc(length);
    assert(_packet != NULL);
    int i = 0;
    while (i <= length) {
        _packet[i] = bytes[i];
        i++;
    }
}

@end
