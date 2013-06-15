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

+ (const char *)JSONWithStringPacket:(NSString *)packet {
    return [TSPacketSerializer JSONWithStringPacket:packet sender:nil];
}

+ (const char *)JSONWithStringPacket:(NSString *)packet sender:(NSString *)sender{
    NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
    [kvDictionary setObject:@"plaster-text" forKey:@"plaster-type"];
    if (sender) {
        [kvDictionary setObject:sender forKey:@"plaster-sender"];        
    }
    NSString *b64 = [[NSString alloc] initWithString:[packet base64String]];
    [kvDictionary setObject:b64 forKey:@"plaster-data"];
    [b64 release];
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
    if (error) {
        NSLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
        return NULL;
    }
    [TSPacketSerializer logJSONToFile:json];
    NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
    return [string UTF8String];
}

+ (NSDictionary *)dictionaryFromJSON:(const char *)json {
    NSData *data = [NSData dataWithBytes:json length:strlen(json)];
    NSError *error = nil;
    id kvStore = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"SERIALIZER: Error occured during de-serialization: %@", error);
        return nil;
    }
    if ([kvStore isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dictionary = (NSMutableDictionary *)kvStore;
        id packet64 = [dictionary objectForKey:@"plaster-data"];
        //NSLog(@"base64 encoded packet : %@", [packet64 class]);
        if ([packet64 isKindOfClass:[NSString class]]) {
            NSData *packet = [(NSString*)packet64 dataFromBase64];
            if (packet) {
                NSString *type = (NSString *)[dictionary objectForKey:@"plaster-type"];
                if ([type isEqualToString:@"plaster-text"]) {
                    NSString *cleared = [[NSString alloc] initWithData:packet encoding:NSUTF8StringEncoding];
                    //NSLog(@"Obtained text packet : %@", cleared);
                    [dictionary setObject:cleared forKey:@"plaster-packet-string"];
                    [cleared release];
                }
            }
        }
        return dictionary;
    }

    return nil;
}

+ (void)logJSONToFile:(NSData *)data {
    NSString *jsonLog = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"plaster_json_out.log"];
    //NSLog(@"PLASTER: TESTING : Writing to [%@]", jsonLog);
    NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath:jsonLog];
    if (log) {
        [log truncateFileAtOffset:[log seekToEndOfFile]];
        [log writeData:data];
        // Write a NL/CR
        [log writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [log closeFile];
    }
    
}

@end
