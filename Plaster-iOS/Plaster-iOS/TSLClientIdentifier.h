//
//  TSClientUUIDGenerator.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLClientIdentifier : NSObject

+ (NSString *)createUUID;
+ (NSString *)clientID;

@end
