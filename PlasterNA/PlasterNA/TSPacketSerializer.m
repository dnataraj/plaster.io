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

+ (const char *)JSONWithTextPacket:(NSString *)packet {
    return [TSPacketSerializer JSONWithTextPacket:packet sender:nil];
}

+ (const char *)JSONWithTextPacket:(id)packet sender:(NSString *)sender {
    NSString *stringRep = nil;
    if ([packet isKindOfClass:[NSAttributedString class]]) {
        stringRep = [(NSAttributedString *)packet string];
    } else {
        stringRep = [NSString stringWithString:packet];
    }
    if (stringRep) {
        NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
        [kvDictionary setObject:TSPlasterTypeText forKey:TSPlasterJSONKeyForPlasterType];
        if (sender) {
            [kvDictionary setObject:sender forKey:TSPlasterJSONKeyForSenderID];
        }
        NSString *b64 = [[NSString alloc] initWithString:[stringRep base64String]];
        [kvDictionary setObject:b64 forKey:TSPlasterJSONKeyForData];
        [b64 release];
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
        if (error) {
            DLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
            return NULL;
        }
        //[TSPacketSerializer logJSONToFile:json];
        NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
        return [string UTF8String];
    }
    
    DLog(@"PACKET SERIALIZER: Unable to obtain string representation");
    return nil;
}

+ (const char *)JSONWithImagePacket:(NSImage *)packet sender:(NSString *)sender {
    NSData *tiffRep = [packet TIFFRepresentation];
    if (tiffRep) {
        NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
        [kvDictionary setObject:TSPlasterTypeImage forKey:TSPlasterJSONKeyForPlasterType];
        if (sender) {
            [kvDictionary setObject:sender forKey:TSPlasterJSONKeyForSenderID];
        }
        NSData *imageData = [[NSData alloc] initWithData:tiffRep];
        NSString *b64 = [imageData base64String];
        [imageData release];
        [kvDictionary setObject:b64 forKey:TSPlasterJSONKeyForData];
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
        if (error) {
            DLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
            return NULL;
        }
        NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
        return [string UTF8String];
    }
    DLog(@"PACKET SERIALIZER: Unable to obtain tiff representation.");
    
    return nil;
}

+ (const char *)JSONWithNotificationPacket:(id)packet sender:(NSString *)sender {
    NSString *stringRep = nil;
    if ([packet isKindOfClass:[NSAttributedString class]]) {
        stringRep = [(NSAttributedString *)packet string];
    } else {
        stringRep = [NSString stringWithString:packet];
    }
    if (stringRep) {
        NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
        [kvDictionary setObject:TSPlasterTypeNotification forKey:TSPlasterJSONKeyForPlasterType];
        if (sender) {
            [kvDictionary setObject:sender forKey:TSPlasterJSONKeyForSenderID];
        }
        NSString *b64 = [[NSString alloc] initWithString:[stringRep base64String]];
        [kvDictionary setObject:b64 forKey:TSPlasterJSONKeyForData];
        [b64 release];
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:kvDictionary options:0 error:&error];
        if (error) {
            DLog(@"PACKET SERIALIZER: Error occured during serialization : %@", error);
            return NULL;
        }
        NSString *string = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
        return [string UTF8String];
    }
    
    DLog(@"PACKET SERIALIZER: Unable to obtain string representation");
    return nil;
}


+ (const char *)JSONWithDataPacket:(NSData *)packet sender:(NSString *)sender {
    if (packet) {
        NSMutableDictionary *kvDictionary = [NSMutableDictionary dictionary];
        [kvDictionary setObject:TSPlasterTypeFile forKey:TSPlasterJSONKeyForPlasterType];
        if (sender) {
            [kvDictionary setObject:sender forKey:TSPlasterJSONKeyForSenderID];
        }
        NSData *data = [[NSData alloc] initWithData:packet]; // just so we have access to our b64 category
        NSString *b64 = [data base64String];
        [data release];
        [kvDictionary setObject:b64 forKey:TSPlasterJSONKeyForData];
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
        DLog(@"PACKET SERIALIZER: Error occured during de-serialization: %@", error);
        return nil;
    }
    if ([kvStore isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dictionary = (NSMutableDictionary *)kvStore;
        id packet64 = [dictionary objectForKey:TSPlasterJSONKeyForData];
        if (packet64 && [packet64 isKindOfClass:[NSString class]]) {
            NSData *packet = [(NSString*)packet64 dataFromBase64];
            DLog(@"PACKET SERIALIZER: Obtained data packet.");
            if (packet) {
                NSString *type = (NSString *)[dictionary objectForKey:TSPlasterJSONKeyForPlasterType];
                if ([type isEqualToString:TSPlasterTypeText] || [type isEqualToString:TSPlasterTypeNotification]) {
                    DLog(@"PACKET SERIALIZER: Converting data to text...");
                    NSString *cleared = [[NSString alloc] initWithData:packet encoding:NSUTF8StringEncoding]; // TODO : This could be optimized in FILE_MODE??
                    [dictionary setObject:cleared forKey:TSPlasterPacketText];
                    [cleared release];
                } else if ([type isEqualToString:TSPlasterTypeImage]) {
                    DLog(@"PACKET SERIALIZER: Converting data to image...");
                    NSImage *image = [[NSImage alloc] initWithData:packet];
                    [dictionary setObject:image forKey:TSPlasterPacketImage];
                    [image release];
                } else {
                    DLog(@"PACKET SERIALIZER: Packet is a file...");
                    [dictionary setObject:packet forKey:TSPlasterPacketFile];
                }
                return dictionary;
            } else {
                DLog(@"PACKET SERIALIZER: Packet was empty.");
            }
        }
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
