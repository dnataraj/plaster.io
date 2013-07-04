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
#import "TSProfileConfigurationViewController.h"

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
        _profiles = nil;
        _sessionKeys = nil;
        _profileConfigurations = nil;
        _profileViewController = [[TSProfileConfigurationViewController alloc] init];
    }
    
    return self;
}

- (void)awakeFromNib {
    DLog(@"PREFERENCES: Waking up...");
    if (_profileViewController) {
        [_profileConfigurationView addSubview:[_profileViewController view]];
    }
    
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
            NSMutableDictionary *configuration = [[NSMutableDictionary alloc] initWithDictionary:[_profiles objectForKey:sessionKey]];
            [_profileConfigurations addObject:configuration];
            [configuration release];
        }
    }
    
    // If there are no profiles, disable the profile configuration pane.
    if (![_sessionKeys count]) {
        [_sessionKeyLabelField setStringValue:@" -- "];
        [_profileViewController disableProfileConfiguration];
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

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSMutableDictionary *profileChanges = [_profileConfigurations objectAtIndex:row];
    
    DLog(@"PREFERENCES: Changing profile name to : %@", object);
    [profileChanges setObject:object forKey:TSPlasterProfileName];

    // Now we have to set this change back into the parent profile collection (remember : we have a mutable copy)
    [_profiles setObject:profileChanges forKey:[_sessionKeys objectAtIndex:row]];
}

/*
    When the user changes rows, configure the corresponding profile
*/
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *profilesTable = [notification object];
    [self configureWithRow:[profilesTable selectedRow]];
    return;
}

/*
    When the user selects another row, make sure any edits are captured.
*/
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    NSInteger previousRow = [tableView selectedRow];
    [self registerConfigurationForRow:previousRow];
    return YES;
}

#pragma mark Profile loading/storing methods

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
    
    // Save any existing edits (say during a window reload after browsing for a folder
    NSInteger row = [self.profileListTableView selectedRow];
    if ( (row >= 0) && (row < [_sessionKeys count]) ) {
        NSDictionary *edits = [_profileViewController getProfileConfiguration];
        NSMutableDictionary *profileChanges = [_profileConfigurations objectAtIndex:row];
        [profileChanges addEntriesFromDictionary:edits];
        [_profiles setObject:profileChanges forKey:[_sessionKeys objectAtIndex:row]];
    }
    
    [self.profileListTableView reloadData];
    [self configureWithRow:[self.profileListTableView selectedRow]];
}

- (void)configureWithRow:(NSInteger)row {
    if (![_sessionKeys count] || (row < 0)) {
        return;
    }
    [_sessionKeyLabelField setStringValue:_sessionKeys[row]];
    [_profileViewController configureWithProfile:[_profileConfigurations objectAtIndex:row]];
    
}

- (void)registerConfigurationForRow:(NSInteger)row {
    if ( (row >= 0) && (row < [_sessionKeys count]) ) {
        // We are operating on a reference here, so this change SHOULD be reflected in our profiles dictionary
        // (which itself is a mutable copy of the dictionary obtained from NSUserDefaults)
        NSDictionary *edits = [_profileViewController getProfileConfiguration];
        NSMutableDictionary *profileChanges = [_profileConfigurations objectAtIndex:row];
        [profileChanges addEntriesFromDictionary:edits];
        // Now we have to set this change back into the parent profile collection (remember : we have a mutable copy)
        [_profiles setObject:profileChanges forKey:[_sessionKeys objectAtIndex:row]];
    }
    
}

- (IBAction)deleteProfile:(id)sender {
    NSInteger rowForDelete = [self.profileListTableView selectedRow];
    DLog(@"PREFERENCES: Deleting row : %ld", rowForDelete);

    NSString *keyForDelete = [_sessionKeys objectAtIndex:rowForDelete];
    [_profiles removeObjectForKey:keyForDelete];
    [_profileConfigurations removeObjectAtIndex:rowForDelete];
    [_sessionKeys removeObjectAtIndex:rowForDelete];
    
    // If that was the last row, then disable configuration editing
    if (![_sessionKeys count]) {
        [_sessionKeyLabelField setStringValue:@" -- "];
        [_profileViewController disableProfileConfiguration];
    }
    
    // Reload the table view after deleting a row
    [self.profileListTableView reloadData];
    // Switch the configuration view to show the configuration of the next selected profile
    [self configureWithRow:[self.profileListTableView selectedRow]];
}

- (void)cancelPreferences:(id)sender {
    [self.window close];
}

- (void)saveAndClosePreferences:(id)sender {
    DLog(@"PREFERENCES: Saving user preferences and closing...");
    // Capture the last selected row's configuration (since we usually capture this only on switching to another row)
    [self registerConfigurationForRow:[_profileListTableView selectedRow]];
    
    [self setDeviceName:[_deviceNameTextField stringValue]];
    if ([_deviceName isEqualToString:@""]) {
        [self setDeviceName:[[NSHost currentHost] localizedName]];
    }
    [_userDefaults setObject:_deviceName forKey:TSPlasterDeviceName];
    [_userDefaults removeObjectForKey:TSPlasterProfiles];
    [_userDefaults setObject:_profiles forKey:TSPlasterProfiles];
    [_userDefaults synchronize];
    
    [self.window close];
}

#pragma mark Window Delegate methods

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self reloadAndConfigure];
}

- (void)windowDidLoad {
    [self configureWithRow:[self.profileListTableView selectedRow]];
}

- (void)dealloc {
    [_userDefaults release];
    [_sessionKeys release];
    [_profileConfigurations release];
    [_profiles release];
    [_profileViewController release];
    
    [super dealloc];
}

@end
