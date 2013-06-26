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
    NSMutableDictionary *_profiles;
    NSMutableArray *_sessionKeys;
    NSMutableArray *_profileConfigurations;
}

- (id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        _userDefaults = [[NSUserDefaults standardUserDefaults] retain];
    }
    
    return self;
}

- (void)reloadAndConfigure {
    // Release what we have, and re-init
    [_profiles release];
    [_sessionKeys release];
    [_profileConfigurations release];
    
    NSMutableDictionary *mutableProfiles = [[_userDefaults dictionaryForKey:TSPlasterProfiles] mutableCopy];
    _profiles = [[NSMutableDictionary alloc] initWithDictionary:mutableProfiles];
    [mutableProfiles release];
    _sessionKeys = [[NSMutableArray alloc] initWithArray:[_profiles allKeys]];
    _profileConfigurations = [[NSMutableArray alloc] init];
    if ([_sessionKeys count] > 0) {
        for (NSString *sessionKey in _sessionKeys) {
            NSMutableDictionary *configuration = [[_profiles objectForKey:sessionKey] mutableCopy];
            [_profileConfigurations addObject:configuration];
            [configuration release];
        }
    }
    [self.profileListTableView reloadData];
    [self configureProfileView:[self.profileListTableView selectedRow]];    
}

- (void)awakeFromNib {
    [self setDeviceName:[_userDefaults stringForKey:TSPlasterDeviceName]];
    
    // Create a mutable copy of the profiles stored in the user's preferences.
    // Maintain a list of session key references to display in the profiles table
    // Maintain a list of profile configuration dictionarie references to display/edit
    NSMutableDictionary *mutableProfiles = [[_userDefaults dictionaryForKey:TSPlasterProfiles] mutableCopy];
    _profiles = [[NSMutableDictionary alloc] initWithDictionary:mutableProfiles];
    [mutableProfiles release];
    _sessionKeys = [[NSMutableArray alloc] initWithArray:[_profiles allKeys]];
    _profileConfigurations = [[NSMutableArray alloc] init];
    if ([_sessionKeys count] > 0) {
        for (NSString *sessionKey in _sessionKeys) {
            NSMutableDictionary *configuration = [[NSMutableDictionary alloc] initWithDictionary:[[_profiles objectForKey:sessionKey] mutableCopy]];
            [_profileConfigurations addObject:configuration];
            [configuration release];
        }
    }
    
    // If there are no profiles, disable the profile configuration pane.
    if (![_sessionKeys count]) {
        [self disableProfileConfigurations];
    }
}

#pragma mark TableView Data Source and Delegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_sessionKeys count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([_profileConfigurations count] > row) {
        NSDictionary *profileConfiguration = [_profileConfigurations objectAtIndex:row];
        return [profileConfiguration objectForKey:TSPlasterProfileName];
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *profilesTable = [notification object];
    [self configureProfileView:[profilesTable selectedRow]];
}

/*
    When the user selects another row, make sure any edits are captured.
*/
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    NSInteger previousRow = [tableView selectedRow];
    [self registerConfigurationForRow:previousRow];
    return YES;
}

- (void)registerConfigurationForRow:(NSInteger)row {
    if ( (row >= 0) && (row < [_sessionKeys count]) ) {
        // We are operating on a reference here, so this change SHOULD be reflected in our profiles dictionary
        // (which itself is a mutable copy of the dictionary obtained from NSUserDefaults)
        NSMutableDictionary *profileChanges = [_profileConfigurations objectAtIndex:row];
        [profileChanges setObject:[NSNumber numberWithBool:self.handlesTextType] forKey:TSPlasterAllowText];
        [profileChanges setObject:[NSNumber numberWithBool:self.handlesImageType] forKey:TSPlasterAllowImages];
        [profileChanges setObject:[NSNumber numberWithBool:self.handlesFileType] forKey:TSPlasterAllowFiles];
        
        if ([self.plasterLocationMatrix selectedCell] == [self.plasterLocationMatrix cellAtRow:0 column:0]) {
            [profileChanges setObject:TSPlasterModePasteboard forKey:TSPlasterMode];
        } else if ([self.plasterLocationMatrix selectedCell] == [self.plasterLocationMatrix cellAtRow:1 column:0]) {
            [profileChanges setObject:TSPlasterModeFile forKey:TSPlasterMode];
            if ([self.plasterLocationFileTextField stringValue]) {
                [profileChanges setObject:[self.plasterLocationFileTextField stringValue] forKey:TSPlasterFolderPath];
            } else {
                [profileChanges setObject:NSHomeDirectory() forKey:TSPlasterFolderPath];
            }
        }
        
        [profileChanges setObject:[NSNumber numberWithBool:self.shouldNotifyJoins] forKey:TSPlasterNotifyJoins];
        [profileChanges setObject:[NSNumber numberWithBool:self.shouldNotifyDepartures] forKey:TSPlasterNotifyDepartures];
        [profileChanges setObject:[NSNumber numberWithBool:self.shouldNotifyPlasters] forKey:TSPlasterNotifyPlasters];
        
        // Now we have to set this change back into the parent profile collection (remember : we have a mutable copy)
        [_profiles setObject:profileChanges forKey:[_sessionKeys objectAtIndex:row]];
    }
    
}

/*
    Set the configuration for a selected profile.
*/
- (void)configureProfileView:(NSInteger)row {
    if (![_sessionKeys count] || (row < 0)) {
        return;
    }
    NSDictionary *profileConfiguration = [_profileConfigurations objectAtIndex:row];
    if (profileConfiguration) {
        [_handleTextTypeButton setEnabled:YES];
        self.handlesTextType = [[profileConfiguration objectForKey:TSPlasterAllowText] boolValue];
        [_handleImageTypeButton setEnabled:YES];
        self.handlesImageType = [[profileConfiguration objectForKey:TSPlasterAllowImages] boolValue];
        [_handleFileTypeButton setEnabled:YES];
        self.handlesFileType = [[profileConfiguration objectForKey:TSPlasterAllowFiles] boolValue];
        
        NSString *mode = [profileConfiguration objectForKey:TSPlasterMode];
        [self.plasterLocationMatrix setEnabled:YES];
        if ([mode isEqualToString:TSPlasterModePasteboard]) {
            [self enablePasteboardMode];
        } else if ([mode isEqualToString:TSPlasterModeFile]) {
            [self enableFileMode];
        }
        NSString *plasterFolder = [profileConfiguration objectForKey:TSPlasterFolderPath];
        if (!plasterFolder) {
            plasterFolder = NSHomeDirectory();
        }
        [self.plasterLocationFileTextField setStringValue:plasterFolder];
        
        [_shouldNotifyJoinsButton setEnabled:YES];
        self.shouldNotifyJoins = [[profileConfiguration objectForKey:TSPlasterNotifyJoins] boolValue];
        [_shouldNotifyDeparturesButton setEnabled:YES];
        self.shouldNotifyDepartures = [[profileConfiguration objectForKey:TSPlasterNotifyDepartures] boolValue];
        [_shouldNotifyPlastersButton setEnabled:YES];
        self.shouldNotifyPlasters = [[profileConfiguration objectForKey:TSPlasterNotifyPlasters] boolValue];
    }
}

- (void)enablePasteboardMode {
    [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:1];
    [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:0];
    [self.plasterLocationFileTextField setEnabled:NO];
    [self.browseButton setEnabled:NO];
    [self.handleFileTypeButton setEnabled:NO];    
}

- (void)enableFileMode {
    [[self.plasterLocationMatrix cellAtRow:0 column:0] setState:0];
    [[self.plasterLocationMatrix cellAtRow:1 column:0] setState:1];
    [self.plasterLocationFileTextField setEnabled:YES];
    [self.browseButton setEnabled:YES];
    [self.handleFileTypeButton setEnabled:YES];    
}

- (void)disableProfileConfigurations {
    [self.handleTextTypeButton setEnabled:NO];
    [self.handleImageTypeButton setEnabled:NO];
    [self.handleFileTypeButton setEnabled:NO];
    [self.browseButton setEnabled:NO];
    [self.plasterLocationFileTextField setEnabled:NO];
    [self.plasterLocationMatrix setEnabled:NO];
    [self.shouldNotifyJoinsButton setEnabled:NO];
    [self.shouldNotifyPlastersButton setEnabled:NO];
    [self.shouldNotifyDeparturesButton setEnabled:NO];
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
        [self enablePasteboardMode];
    } else if ([self.plasterLocationMatrix cellAtRow:1 column:0] == [sender selectedCell]) {
        [self enableFileMode];
    }
}

- (IBAction)deleteProfile:(id)sender {
    NSInteger rowForDelete = [self.profileListTableView selectedRow];
    NSLog(@"PREFERENCES: Deleting row : %ld", rowForDelete);

    NSString *keyForDelete = [_sessionKeys objectAtIndex:rowForDelete];
    [_profiles removeObjectForKey:keyForDelete];
    [_profileConfigurations removeObjectAtIndex:rowForDelete];
    [_sessionKeys removeObjectAtIndex:rowForDelete];
    
    // If that was the last row, then disable configuration editing
    if (![_sessionKeys count]) {
        [self disableProfileConfigurations];
    }
    
    // Reload the table view after deleting a row
    [self.profileListTableView reloadData];
    // Switch the configuration view to show the configuration of the next selected profile
    [self configureProfileView:[self.profileListTableView selectedRow]];
}

- (void)cancelPreferences:(id)sender {
    //[self reloadAndConfigure];
    [self.window close];
}

- (void)saveAndClosePreferences:(id)sender {
    NSLog(@"PREFERENCES: Saving user preferences and closing...");
    // Capture the last selected row's configuration (since we usually capture this only on switching to another row)
    [self registerConfigurationForRow:[_profileListTableView selectedRow]];
    
    [self setDeviceName:[_deviceNameTextField stringValue]];
    if ([_deviceName isEqualToString:@""]) {
        [self setDeviceName:[[NSHost currentHost] localizedName]];
    }
    [_userDefaults setObject:_deviceName forKey:TSPlasterDeviceName];
    [_userDefaults removeObjectForKey:TSPlasterProfiles];
    //NSLog(@"PREFERENCES: Saving profiles : %@", _profiles);
    [_userDefaults setObject:_profiles forKey:TSPlasterProfiles];
    [_userDefaults synchronize];
    
    [self.window close];
}

#pragma mark Window Delegate methods
- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self reloadAndConfigure];
}

- (void)windowDidLoad {
    NSLog(@"PREFERENCES: Loading...");
    [self configureProfileView:[self.profileListTableView selectedRow]];
}

- (void)dealloc {
    [_userDefaults release];
    [_sessionKeys release];
    [_profileConfigurations release];
    [_profiles release];
    
    [super dealloc];
}

@end
