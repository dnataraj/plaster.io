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
-(void)setStringValueAsynchronous:(NSString *)stringValue forKey:(NSString *)key;
-(void)setStringValue:(NSString *)stringValue forKey:(NSString *)key;

-(BOOL)setNXStringValue:(NSString *)stringValue forKey:(NSString *)key;

-(NSString *)stringValueForKeyAsynchronous:(NSString *)key;
-(NSString *)stringValueForKey:(NSString *)key;

-(void)setDictionaryValue:(NSDictionary *)dictionary forKey:(NSString *)key;
-(NSDictionary *)dictionaryValueForKey:(NSString *)key;
-(NSArray *)dictionaryKeysForKey:(NSString *)key;
-(NSUInteger)incrementKey:(NSString *)key;
-(NSUInteger)deleteKey:(NSString *)key;

@end
