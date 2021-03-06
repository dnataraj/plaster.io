//
//  TSPacketSerializer.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLPacketSerializer : NSObject

+ (const char *)JSONWithTextPacket:(id)packet;
+ (const char *)JSONWithTextPacket:(id)packet sender:(NSString *)sender;
+ (const char *)JSONWithImagePacket:(UIImage *)packet sender:(NSString *)sender;
+ (const char *)JSONWithNotificationPacket:(id)packet sender:(NSString *)sender;
+ (const char *)JSONWithDataPacket:(NSData *)packet sender:(NSString *)sender;

+ (NSDictionary *)dictionaryFromJSON:(const char *)json;

@end
