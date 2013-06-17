//
//  TSPacketSerializer.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPacketSerializer.h"
#import "TSBase64/NSString+TSBase64.h"
#import "TSBase64/NSData+TSBase64.h"
#import "TSPlasterGlobals.h"

@implementation TSPacketSerializer

+ (const char *)JSONWithStringPacket:(NSString *)packet {
    return [TSPacketSerializer JSONWithStringPacket:packet sender:nil];
}

+ (const char *)JSONWithStringPacket:(NSString *)packet sender:(NSString *)sender{
    NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
    [kvDictionary setObject:PLASTER_TEXT_TYPE_JSON_VALUE forKey:PLASTER_TYPE_JSON_KEY];
    if (sender) {
        [kvDictionary setObject:sender forKey:PLASTER_SENDER_JSON_KEY];
    }
    NSString *b64 = [[NSString alloc] initWithString:[packet base64String]];
    [kvDictionary setObject:b64 forKey:PLASTER_DATA_JSON_KEY];
    [b64 release];
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
    if (error) {
        NSLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
        return NULL;
    }
    //[TSPacketSerializer logJSONToFile:json];
    NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
    return [string UTF8String];
}

+ (const char *)JSONWithImagePacket:(NSImage *)packet sender:(NSString *)sender{
    NSData *tiffRep = [packet TIFFRepresentation];
    if (tiffRep) {
        NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
        [kvDictionary setObject:PLASTER_IMAGE_TYPE_JSON_VALUE forKey:PLASTER_TYPE_JSON_KEY];
        if (sender) {
            [kvDictionary setObject:sender forKey:PLASTER_SENDER_JSON_KEY];
        }
        NSData *imageData = [[NSData alloc] initWithData:tiffRep];
        NSString *b64 = [imageData base64String];
        [imageData release];
        [kvDictionary setObject:b64 forKey:PLASTER_DATA_JSON_KEY];
        [b64 release];
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
        if (error) {
            NSLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
            return NULL;
        }
        NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
        return [string UTF8String];
    }
    NSLog(@"PACKET SERIALIZER: Unable to obtain tiff representation.");
    
    return nil;
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
        id packet64 = [dictionary objectForKey:PLASTER_DATA_JSON_KEY];
        if ([packet64 isKindOfClass:[NSString class]]) {
            NSData *packet = [(NSString*)packet64 dataFromBase64];
            if (packet) {
                NSString *type = (NSString *)[dictionary objectForKey:PLASTER_TYPE_JSON_KEY];
                if ([type isEqualToString:PLASTER_TEXT_TYPE_JSON_VALUE]) {
                    NSString *cleared = [[NSString alloc] initWithData:packet encoding:NSUTF8StringEncoding];
                    [dictionary setObject:cleared forKey:PLASTER_PACKET_TEXT];
                    [cleared release];
                } else if ([type isEqualToString:PLASTER_IMAGE_TYPE_JSON_VALUE]) {
                    NSLog(@"PACKET SERIALIZER: Converting data to image...");
                    NSImage *image = [[NSImage alloc] initWithData:packet];
                    [dictionary setObject:image forKey:PLASTER_PACKET_IMAGE];
                    [image release];
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
