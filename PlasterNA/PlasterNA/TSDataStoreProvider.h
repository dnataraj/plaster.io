//
//  TSDataStoreProvider.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSDataStoreProvider <NSObject>

@optional
- (NSUInteger)setStringValue:(NSString *)stringValue forKey:(NSString *)key;
- (NSUInteger)setByteValue:(const char *)byteValue forKey:(NSString *)key;
- (NSUInteger)setByteValue:(const char *)byteValue forKey:(NSString *)key withOptions:(NSDictionary *)options;
- (NSString *)stringValueForKey:(NSString *)key;
- (NSUInteger)setExpiry:(NSUInteger)expiry forKey:(NSString *)key;

- (void)setDictionaryValue:(NSDictionary *)dictionary forKey:(NSString *)key;
- (NSDictionary *)dictionaryValueForKey:(NSString *)key;
- (NSArray *)dictionaryKeysForKey:(NSString *)key;
- (NSUInteger)incrementKey:(NSString *)key;
- (NSUInteger)deleteKey:(NSString *)key;

@end
