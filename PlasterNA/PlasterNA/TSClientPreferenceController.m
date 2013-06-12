//
//  TSClientPreferenceController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSClientPreferenceController.h"
#import "TSClientIdentifier.h"

@interface TSClientPreferenceController ()

@property (readwrite, copy) NSString *sessionID;

@end

@implementation TSClientPreferenceController {
    NSUserDefaults *_userDefaults;
}

- (id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _sessionID = [_userDefaults stringForKey:@"plaster-session-id"];
        _handlesTextType = [_userDefaults boolForKey:@"plaster-allow-text"];
        _handlesImageType = [_userDefaults boolForKey:@"plaster-allow-images"];
        _deviceName = [_userDefaults stringForKey:@"plaster-device-name"];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Saving user preferences...");
    [_userDefaults setObject:[self deviceName] forKey:@"plaster-device-name"];
    [_userDefaults setObject:[self sessionID] forKey:@"plaster-session-id"];
    [_userDefaults setBool:[self handlesTextType] forKey:@"plaster-allow-text"];
    [_userDefaults setBool:[self handlesImageType] forKey:@"plaster-allow-images"];
}

- (void)windowDidLoad {
    [self.deviceNameTextField setStringValue:[self deviceName]];
    [self.sessionIDTextField setStringValue:[self sessionID]];
    [self.handleTextTypeButton setState:[self handlesTextType]];
    [self.handleImageTypeButton setState:[self handlesImageType]];
}

- (IBAction)generateSessionID:(id)sender {
    NSLog(@"Generating new session ID...");
    [self willChangeValueForKey:@"sessionID"];
    self.sessionID = [TSClientIdentifier createUUID];
    [self didChangeValueForKey:@"sessionID"];
}

@end
