//
//  TSPacketSerializer.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPacketSerializer : NSObject

+ (const void *)JSONWithStringPacket:(NSString *)packet;
+ (NSDictionary *)dictionaryFromJSON:(const char *)json;

@end
