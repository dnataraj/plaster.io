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
    return [(NSString *)uuidStrRef autorelease];
}

+ (NSString *)clientID {
    return _clientID;
}

- (void)dealloc {
    [_clientID release];
    [super dealloc];
}

@end
