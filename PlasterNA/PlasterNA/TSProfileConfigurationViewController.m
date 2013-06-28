//
//  TSProfileConfigurationViewController.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/26/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSProfileConfigurationViewController.h"
#import "TSPlasterGlobals.h"

@interface TSProfileConfigurationViewController ()

@end

@implementation TSProfileConfigurationViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

- (id)init {
    return [self initWithNibName:@"ProfileConfiguration" bundle:nil];
}

- (void)enablePasteboardMode {
    [[self.plasterLocationSelectionMatrix cellAtRow:0 column:0] setState:1];
    [[self.plasterLocationSelectionMatrix cellAtRow:1 column:0] setState:0];
    [self.plasterFolderLocationTextField setEnabled:NO];
    [self.plasterFolderLocationBrowseButton setEnabled:NO];
    [self.handleInFileTypeButton setEnabled:NO];
}

- (void)enableFileMode {
    [[self.plasterLocationSelectionMatrix cellAtRow:0 column:0] setState:0];
    [[self.plasterLocationSelectionMatrix cellAtRow:1 column:0] setState:1];
    [self.plasterFolderLocationTextField setEnabled:YES];
    [self.plasterFolderLocationBrowseButton setEnabled:YES];
    [self.handleInFileTypeButton setEnabled:YES];
}

- (void)disableProfileConfiguration {
    [self.handleInTextTypeButton setEnabled:NO];
    [self.handleInImageTypeButton setEnabled:NO];
    [self.handleInFileTypeButton setEnabled:NO];
    [self.handleOutTextTypeButton setEnabled:NO];
    [self.handleOutImageTypeButton setEnabled:NO];
    [self.handleOutFileTypeButton setEnabled:NO];
    [self.plasterFolderLocationBrowseButton setEnabled:NO];
    [self.plasterFolderLocationBrowseButton setEnabled:NO];
    [self.plasterLocationSelectionMatrix setEnabled:NO];
    [self.shouldNotifyJoinsButton setEnabled:NO];
    [self.shouldNotifyPlastersButton setEnabled:NO];
    [self.shouldNotifyDeparturesButton setEnabled:NO];
}

- (NSDictionary *)getProfileConfiguration {
    NSMutableDictionary *profileConfiguration = [NSMutableDictionary dictionary];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesInTextType] forKey:TSPlasterAllowText];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesInImageType] forKey:TSPlasterAllowImages];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesInFileType] forKey:TSPlasterAllowFiles];
    
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutTextType] forKey:TSPlasterOutAllowText];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutImageType] forKey:TSPlasterOutAllowImages];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutFileType] forKey:TSPlasterOutAllowFiles];
    
    if ([self.plasterLocationSelectionMatrix selectedCell] == [self.plasterLocationSelectionMatrix cellAtRow:0 column:0]) {
        [profileConfiguration setObject:TSPlasterModePasteboard forKey:TSPlasterMode];
    } else if ([self.plasterLocationSelectionMatrix selectedCell] == [self.plasterLocationSelectionMatrix cellAtRow:1 column:0]) {
        [profileConfiguration setObject:TSPlasterModeFile forKey:TSPlasterMode];
        if ([self.plasterFolderLocationTextField stringValue]) {
            [profileConfiguration setObject:[self.plasterFolderLocationTextField stringValue] forKey:TSPlasterFolderPath];
        } else {
            [profileConfiguration setObject:NSHomeDirectory() forKey:TSPlasterFolderPath];
        }
    }
    
    [profileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyJoins] forKey:TSPlasterNotifyJoins];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyDepartures] forKey:TSPlasterNotifyDepartures];
    [profileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyPlasters] forKey:TSPlasterNotifyPlasters];
    
    return profileConfiguration;
}

- (void)configureWithProfile:(NSDictionary *)profileConfiguration {
    if (profileConfiguration) {
        [_handleInTextTypeButton setEnabled:YES];
        self.handlesInTextType = [[profileConfiguration objectForKey:TSPlasterAllowText] boolValue];
        [_handleInImageTypeButton setEnabled:YES];
        self.handlesInImageType = [[profileConfiguration objectForKey:TSPlasterAllowImages] boolValue];
        [_handleInFileTypeButton setEnabled:YES];
        self.handlesInFileType = [[profileConfiguration objectForKey:TSPlasterAllowFiles] boolValue];
        
        [_handleOutTextTypeButton setEnabled:YES];
        self.handlesOutTextType = [[profileConfiguration objectForKey:TSPlasterOutAllowFiles] boolValue];
        [_handleOutImageTypeButton setEnabled:YES];
        self.handlesOutImageType = [[profileConfiguration objectForKey:TSPlasterOutAllowImages] boolValue];
        [_handleOutFileTypeButton setEnabled:YES];
        self.handlesOutFileType = [[profileConfiguration objectForKey:TSPlasterOutAllowImages] boolValue];
        
        NSString *mode = [profileConfiguration objectForKey:TSPlasterMode];
        [self.plasterLocationSelectionMatrix setEnabled:YES];
        if ([mode isEqualToString:TSPlasterModePasteboard]) {
            [self enablePasteboardMode];
        } else if ([mode isEqualToString:TSPlasterModeFile]) {
            [self enableFileMode];
        }
        NSString *plasterFolder = [profileConfiguration objectForKey:TSPlasterFolderPath];
        if (!plasterFolder) {
            plasterFolder = NSHomeDirectory();
        }
        [self.plasterFolderLocationTextField setStringValue:plasterFolder];
        
        [_shouldNotifyJoinsButton setEnabled:YES];
        self.shouldNotifyJoins = [[profileConfiguration objectForKey:TSPlasterNotifyJoins] boolValue];
        [_shouldNotifyDeparturesButton setEnabled:YES];
        self.shouldNotifyDepartures = [[profileConfiguration objectForKey:TSPlasterNotifyDepartures] boolValue];
        [_shouldNotifyPlastersButton setEnabled:YES];
        self.shouldNotifyPlasters = [[profileConfiguration objectForKey:TSPlasterNotifyPlasters] boolValue];
    }
}

- (IBAction)plasterFolderLocationBrowse:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:YES];
    void (^openPanelDidEnd) (NSInteger) = ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSString *path = [[panel URL] path];
            [self.plasterFolderLocationTextField setStringValue:path];
        }
    };
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:openPanelDidEnd];
}

- (IBAction)switchPlasterDestination:(id)sender {
    if ([self.plasterLocationSelectionMatrix cellAtRow:0 column:0] == [sender selectedCell]) {
        [self enablePasteboardMode];
    } else if ([self.plasterLocationSelectionMatrix cellAtRow:1 column:0] == [sender selectedCell]) {
        [self enableFileMode];
    }
}



@end
