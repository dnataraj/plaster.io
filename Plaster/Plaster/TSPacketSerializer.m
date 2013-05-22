//
//  TSPacketSerializer.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPacketSerializer.h"
#import "TSBase64/NSString+TSBase64.h"

@implementation TSPacketSerializer

+ (const void *)JSONWithStringPacket:(NSString *)packet {
    NSMutableDictionary *kvDictionary = [[NSMutableDictionary alloc] init];
    [kvDictionary setObject:@"plaster-text" forKey:@"plaster-type"];
    NSString *b64 = [packet base64String];
    NSLog(@"BASE 64 ENCODED : [%@]", b64);
    [kvDictionary setObject:b64 forKey:@"plaster-data"];
    
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
    //NSString *string = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    //NSLog(@"JSON data : %@", string);
    // TODO : Trap error
    return [json bytes];
}

+ (NSDictionary *)dictionaryFromJSON:(const char *)json {
    NSData *data = [NSData dataWithBytes:json length:strlen(json)];
    NSError *error = nil;
    id kvStore = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    //NSLog(@"Retrieved id of type [%@]", [json class]);
    if (error) {
        NSLog(@"Error occured : %@", error);
    }
    if ([kvStore isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dictionary = (NSMutableDictionary *)kvStore;
        id packet64 = [dictionary objectForKey:@"plaster-data"];
        NSLog(@"base64 encoded packet : %@", [packet64 class]);
        if ([packet64 isKindOfClass:[NSString class]]) {
            NSData *packet = [(NSString*)packet64 dataFromBase64];
            if (packet) {
                NSString *type = (NSString *)[dictionary objectForKey:@"plaster-type"];
                if ([type isEqualToString:@"plaster-text"]) {
                    NSString *cleared = [[NSString alloc] initWithData:packet encoding:NSUTF8StringEncoding];
                    NSLog(@"Obtained text packet : %@", cleared);
                    [dictionary setObject:cleared forKey:@"plaster-packet-string"];
                }
            }
        }
        return dictionary;
    }

    return nil;
}
@end
