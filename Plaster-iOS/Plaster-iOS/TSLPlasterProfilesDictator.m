//
//  TSLUserProfileDictator.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterProfilesDictator.h"
#import "TSLPlasterGlobals.h"

@implementation TSLPlasterProfilesDictator {
    NSUserDefaults *_userDefaults;
}

- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [[NSUserDefaults standardUserDefaults] retain];
        
    }
    
    return self;
}

- (NSDictionary *)plasterProfiles {
    return [_userDefaults dictionaryForKey:TSPlasterProfiles];
}

- (void)setPlasterProfiles:(NSDictionary *)profiles {
    [_userDefaults setObject:profiles forKey:TSPlasterProfiles];
}

- (void)addProfile:(NSDictionary *)profile withKey:(NSString *)key {
    NSMutableDictionary *updatedProfiles = [NSMutableDictionary dictionaryWithDictionary:[self plasterProfiles]];
    [updatedProfiles setObject:profile forKey:key];
    [self setPlasterProfiles:updatedProfiles];
}

- (void)removeProfileWithKey:(NSString *)sessionKey {
    NSMutableDictionary *updatedProfiles = [NSMutableDictionary dictionaryWithDictionary:[self plasterProfiles]];
    [updatedProfiles removeObjectForKey:sessionKey];
    [self setPlasterProfiles:updatedProfiles];
}

- (void)saveCurrentSessionWithKey:(NSString *)key {
    [_userDefaults setObject:key forKey:TSCurrentSessionKey];
    return;
}

- (NSString *)currentSessionKey {
    return [_userDefaults objectForKey:TSCurrentSessionKey];
}

- (NSString *)stringForKey:(NSString *)key {
    return [_userDefaults stringForKey:key];
}

- (void)dealloc {
    [_userDefaults release];
    [super dealloc];
}


@end
