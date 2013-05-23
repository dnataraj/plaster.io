//
//  TSClientUUIDGenerator.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSClientIdentifier.h"

static NSString *_clientID = nil;

@implementation TSClientIdentifier

+ (void)initialize {
    _clientID = [TSClientIdentifier createUUID];
}

+ (NSString *)createUUID {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStrRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge_transfer  NSString *)uuidStrRef;
}

+ (NSString *)clientID {
    return _clientID;
}

- (id)init {
    self = [super init];
    if (self) {
        _spiderKey = [TSClientIdentifier createUUID];
        NSLog(@"Initializing client identifier with spider-key [%@]", _spiderKey);
    }
    
    return self;
}

- (void)resetSpiderKey {
    [self setSpiderKey:[TSClientIdentifier createUUID]];
}

@end
