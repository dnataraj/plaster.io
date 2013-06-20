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

    }
    
    return self;
}

- (void)awakeFromNib {
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _sessionKey = [_userDefaults stringForKey:PLASTER_SESSION_KEY_PREF];
    _deviceName = [_userDefaults stringForKey:PLASTER_DEVICE_NAME_PREF];
    
    _handlesTextType = [_userDefaults boolForKey:PLASTER_ALLOW_TEXT_TYPE_PREF];
    _handlesImageType = [_userDefaults boolForKey:PLASTER_ALLOW_IMAGE_TYPE_PREF];
    _handlesFileType = [_userDefaults boolForKey:PLASTER_ALLOW_FILE_TYPE_PREF];
    
    _plasterMode = [_userDefaults stringForKey:PLASTER_MODE_PREF];
    _plasterFolder = [_userDefaults stringForKey:PLASTER_FOLDER_PREF];
    
    _shouldNotifyJoins = [_userDefaults boolForKey:PLASTER_NOTIFY_JOINS_PREF];
    _shouldNotifyDepartures = [_userDefaults boolForKey:PLASTER_NOTIFY_DEPARTURES_PREF];
    _shouldNotifyPlasters = [_userDefaults boolForKey:PLASTER_NOTIFY_PLASTERS_PREF];
}

- (void)browse:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:YES];
    void (^openPanelDidEnd) (NSInteger) = ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSString *path = [[panel URL] path];
            [self.plasterLocationFileTextField setStringValue:path];
        }
    };
    [panel beginSheetModalForWindow:[self window] completionHandler:openPanelDidEnd];
}

- (void)switchPlasterDestination:(id)sender {
    if ([self.plasterLocationMatrix cellAtRow:0 column:0] == [sender selectedCell]) {
        [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:1];
        [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:0];
        [self.plasterLocationFileTextField setEnabled:NO];
        [self.browseButton setEnabled:NO];
        [self.handleFileTypeButton setEnabled:NO];
        self.plasterMode = @"pasteboard";
    } else if ([self.plasterLocationMatrix cellAtRow:1 column:0] == [sender selectedCell]) {
        [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:0];
        [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:1];
        [self.plasterLocationFileTextField setEnabled:YES];
        [self.browseButton setEnabled:YES];
        [self.handleFileTypeButton setEnabled:YES];
        self.plasterMode = @"file";
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Saving user preferences...");
    [_userDefaults setObject:[self deviceName] forKey:PLASTER_DEVICE_NAME_PREF];
    
    [_userDefaults setBool:[self handlesTextType] forKey:PLASTER_ALLOW_TEXT_TYPE_PREF];
    [_userDefaults setBool:[self handlesImageType] forKey:PLASTER_ALLOW_IMAGE_TYPE_PREF];
    [_userDefaults setBool:[self handlesFileType] forKey:PLASTER_ALLOW_FILE_TYPE_PREF];
    
    /*
    if (([self.plasterLocationMatrix selectedCell] == [self.plasterLocationMatrix cellAtRow:1 column:0]) && ([self.plasterFolder length] > 0)) {
        [_userDefaults setObject:@"FILE" forKey:PLASTER_MODE_PREF];
        [_userDefaults setObject:[self plasterFolder] forKey:PLASTER_FOLDER_PREF];
    } else {
        [_userDefaults setObject:@"PASTEBOARD" forKey:PLASTER_MODE_PREF];
    }
    */
    NSLog(@"PREFERENCES: Saving type : %@", self.plasterMode);
    [_userDefaults setObject:self.plasterMode forKey:PLASTER_MODE_PREF];
    [_userDefaults setObject:self.plasterFolder forKey:PLASTER_FOLDER_PREF];
    
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

    if ([self.plasterMode isEqualToString:@"file"]) {
        [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:0];
        [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:1];
        [self.plasterLocationFileTextField setEnabled:YES];
        [self.browseButton setEnabled:YES];
        [self.handleFileTypeButton setEnabled:YES];
    } else {
        [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:1];
        [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:0];
        [self.plasterLocationFileTextField setEnabled:NO];
        [self.browseButton setEnabled:NO];
        [self.handleFileTypeButton setEnabled:NO];
    }

    self.plasterLocationFileTextField.stringValue = _plasterFolder;
        
    [self.shouldNotifyJoinsButton setState:[self shouldNotifyJoins]];
    [self.shouldNotifyDeparturesButton setState:[self shouldNotifyDepartures]];
    [self.shouldNotifyPlastersButton  setState:[self shouldNotifyPlasters]];
}

@end
