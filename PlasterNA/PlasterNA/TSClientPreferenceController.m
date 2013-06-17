//
//  TSClientPreferenceController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSClientPreferenceController.h"
#import "TSClientIdentifier.h"
#import "TSPlasterGlobals.h"

@implementation TSClientPreferenceController {
    NSUserDefaults *_userDefaults;
}

- (id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _sessionKey = [_userDefaults stringForKey:PLASTER_SESSION_KEY_PREF];
        _deviceName = [_userDefaults stringForKey:PLASTER_DEVICE_NAME_PREF];
        
        _handlesTextType = [_userDefaults boolForKey:PLASTER_ALLOW_TEXT_TYPE_PREF];
        _handlesImageType = [_userDefaults boolForKey:PLASTER_ALLOW_IMAGE_TYPE_PREF];
        _handlesFileType = [_userDefaults boolForKey:PLASTER_ALLOW_FILE_TYPE_PREF];
        
        _shouldNotifyJoins = [_userDefaults boolForKey:PLASTER_NOTIFY_JOINS_PREF];
        _shouldNotifyDepartures = [_userDefaults boolForKey:PLASTER_NOTIFY_DEPARTURES_PREF];
        _shouldNotifyPlasters = [_userDefaults boolForKey:PLASTER_NOTIFY_PLASTERS_PREF];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Saving user preferences...");
    [_userDefaults setObject:[self deviceName] forKey:PLASTER_DEVICE_NAME_PREF];
    
    [_userDefaults setBool:[self handlesTextType] forKey:PLASTER_ALLOW_TEXT_TYPE_PREF];
    [_userDefaults setBool:[self handlesImageType] forKey:PLASTER_ALLOW_IMAGE_TYPE_PREF];
    [_userDefaults setBool:[self handlesFileType] forKey:PLASTER_ALLOW_FILE_TYPE_PREF];
    
    [_userDefaults setBool:[self shouldNotifyJoins] forKey:PLASTER_NOTIFY_JOINS_PREF];
    [_userDefaults setBool:[self shouldNotifyDepartures] forKey:PLASTER_NOTIFY_DEPARTURES_PREF];
    [_userDefaults setBool:[self shouldNotifyPlasters] forKey:PLASTER_NOTIFY_PLASTERS_PREF];
    
    [_userDefaults synchronize];
}

- (void)windowDidLoad {
    [self.deviceNameTextField setStringValue:[self deviceName]];
    [self.sessionKeyLabelField setStringValue:[self sessionKey]];
    
    [self.handleTextTypeButton setState:[self handlesTextType]];
    [self.handleImageTypeButton setState:[self handlesImageType]];
    [self.handleFileTypeButton setState:[self handlesFileType]];
    
    [self.shouldNotifyJoinsButton setState:[self shouldNotifyJoins]];
    [self.shouldNotifyDeparturesButton setState:[self shouldNotifyDepartures]];
    [self.shouldNotifyPlastersButton  setState:[self shouldNotifyPlasters]];
}

@end
