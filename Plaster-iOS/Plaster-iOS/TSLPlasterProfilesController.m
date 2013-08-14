//
//  TSLUserProfileDictator.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterProfilesController.h"
#import "TSLPlasterGlobals.h"
#import "TSLRedisController.h"
#import "TSLPlasterProfile.h"

@interface TSLPlasterProfilesController () {
    NSMutableDictionary *_plasterProfiles;
    NSUserDefaults *_userDefaults;
    TSLRedisController *_redisController;
}

- (NSDictionary *)plasterProfiles;

@end

@implementation TSLPlasterProfilesController

- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [[NSUserDefaults standardUserDefaults] retain];
        _redisController = [[TSLRedisController alloc] initWithIPAddress:@"176.9.2.188" port:6379];
        
        _plasterProfiles = [[NSMutableDictionary alloc] init];
        NSDictionary *storedProfiles =  [_userDefaults dictionaryForKey:TSPlasterProfiles];
        NSArray *sessionKeys = [storedProfiles allKeys];
        for (NSString *sessionKey in sessionKeys) {
            DLog(@"Retrieving profile with key : %@", sessionKey);
            NSDictionary *storedProfile = [storedProfiles objectForKey:sessionKey];
            TSLPlasterProfile *plasterProfile = [[[TSLPlasterProfile alloc] initWithProfile:storedProfile sessionKey:sessionKey provider:_redisController] autorelease];
            [_plasterProfiles setObject:plasterProfile forKey:sessionKey];
        }
        
    }
    
    return self;
}

- (NSDictionary *)profiles {
    return [_plasterProfiles copy];
}

- (void)setPlasterProfiles:(NSDictionary *)profiles {
    [_userDefaults setObject:profiles forKey:TSPlasterProfiles];
}

- (NSDictionary *)plasterProfiles {
    return [_userDefaults dictionaryForKey:TSPlasterProfiles];
}

- (void)addProfile:(NSDictionary *)profile withKey:(NSString *)sessionKey {
    // Add this new profile to user preferences
    NSMutableDictionary *updatedProfiles = [NSMutableDictionary dictionaryWithDictionary:[self plasterProfiles]];
    [updatedProfiles setObject:profile forKey:sessionKey];
    [self setPlasterProfiles:updatedProfiles];
    
    // ...and add it to this object's list of wrapped profiles
    TSLPlasterProfile *plasterProfile = [[[TSLPlasterProfile alloc] initWithProfile:profile sessionKey:sessionKey provider:_redisController] autorelease];
    [_plasterProfiles setObject:plasterProfile forKey:sessionKey];
}

- (void)removeProfileWithKey:(NSString *)sessionKey {
    // Remove this profile from user preferences
    NSMutableDictionary *updatedProfiles = [NSMutableDictionary dictionaryWithDictionary:[self plasterProfiles]];
    [updatedProfiles removeObjectForKey:sessionKey];
    [self setPlasterProfiles:updatedProfiles];
    
    // ...and remove it from the list of wrapper profiles
    [_plasterProfiles removeObjectForKey:sessionKey];
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
    [_userDefaults synchronize];
    [_userDefaults release];
    [super dealloc];
}


@end
