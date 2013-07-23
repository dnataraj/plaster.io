//
//  TSLUserProfileDictator.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLUserProfileDictator.h"
#import "TSLPlasterGlobals.h"

@implementation TSLUserProfileDictator {
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
    [_userDefaults synchronize];
}

- (void)addProfile:(NSDictionary *)profile withKey:(NSString *)key {
    
}

- (void)removeProfileWithKey:(NSString *)sessionKey {
    
}

- (void)dealloc {
    [_userDefaults release];
    [super dealloc];
}


@end
