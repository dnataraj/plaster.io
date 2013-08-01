//
//  TSLUserProfileDictator.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLPlasterProfilesDictator : NSObject

- (NSDictionary *)plasterProfiles;
- (void)setPlasterProfiles:(NSDictionary *)profiles;
- (void)removeProfileWithKey:(NSString *)sessionKey;
- (void)addProfile:(NSDictionary *)profile withKey:(NSString *)key;
- (void)saveCurrentSessionWithKey:(NSString *)key;
- (NSString *)currentSessionKey;
- (NSString *)stringForKey:(NSString *)key;

@end
