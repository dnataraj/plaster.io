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

@implementation TSProfileConfigurationViewController {
    NSMutableDictionary *_mutableProfileConfiguration;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mutableProfileConfiguration = nil;
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
    self.plasterMode = TSPlasterModePasteboard;
}

- (void)enableFileMode {
    [[self.plasterLocationSelectionMatrix cellAtRow:0 column:0] setState:0];
    [[self.plasterLocationSelectionMatrix cellAtRow:1 column:0] setState:1];
    [self.plasterFolderLocationTextField setEnabled:YES];
    [self.plasterFolderLocationBrowseButton setEnabled:YES];
    [self.handleInFileTypeButton setEnabled:YES];
    self.plasterMode = TSPlasterModeFile;
}

- (void)disableProfileConfiguration {
    [self.handleInTextTypeButton setEnabled:NO];
    [self.handleInImageTypeButton setEnabled:NO];
    [self.handleInFileTypeButton setEnabled:NO];
    [self.handleOutTextTypeButton setEnabled:NO];
    [self.handleOutImageTypeButton setEnabled:NO];
    [self.handleOutFileTypeButton setEnabled:NO];
    [self.plasterFolderLocationBrowseButton setEnabled:NO];
    [self.plasterFolderLocationTextField setEnabled:NO];
    [self.plasterLocationSelectionMatrix setEnabled:NO];
    [self.shouldNotifyJoinsButton setEnabled:NO];
    [self.shouldNotifyPlastersButton setEnabled:NO];
    [self.shouldNotifyDeparturesButton setEnabled:NO];
}

- (NSMutableDictionary *)getProfileConfiguration {
    if (!_mutableProfileConfiguration) {
        NSLog(@"PROFILE CONFIGURATION MANAGER : No profile to work with");
        return nil;
    }
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesInTextType] forKey:TSPlasterAllowText];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesInImageType] forKey:TSPlasterAllowImages];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesInFileType] forKey:TSPlasterAllowFiles];
    
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutTextType] forKey:TSPlasterOutAllowText];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutImageType] forKey:TSPlasterOutAllowImages];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.handlesOutFileType] forKey:TSPlasterOutAllowFiles];
    
    [_mutableProfileConfiguration setObject:self.plasterMode forKey:TSPlasterMode];
    [_mutableProfileConfiguration setObject:self.plasterFolder forKey:TSPlasterFolderPath];
    
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyJoins] forKey:TSPlasterNotifyJoins];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyDepartures] forKey:TSPlasterNotifyDepartures];
    [_mutableProfileConfiguration setObject:[NSNumber numberWithBool:self.shouldNotifyPlasters] forKey:TSPlasterNotifyPlasters];
    
    return [_mutableProfileConfiguration autorelease];
}

- (void)configureWithProfile:(NSMutableDictionary *)profileConfiguration {
    if (profileConfiguration) {
        _mutableProfileConfiguration = [profileConfiguration retain];
        [_handleInTextTypeButton setEnabled:YES];
        self.handlesInTextType = [[profileConfiguration objectForKey:TSPlasterAllowText] boolValue];
        [_handleInImageTypeButton setEnabled:YES];
        self.handlesInImageType = [[profileConfiguration objectForKey:TSPlasterAllowImages] boolValue];
        [_handleInFileTypeButton setEnabled:YES];
        self.handlesInFileType = [[profileConfiguration objectForKey:TSPlasterAllowFiles] boolValue];
        
        [_handleOutTextTypeButton setEnabled:YES];
        self.handlesOutTextType = [[profileConfiguration objectForKey:TSPlasterOutAllowText] boolValue];
        [_handleOutImageTypeButton setEnabled:YES];
        self.handlesOutImageType = [[profileConfiguration objectForKey:TSPlasterOutAllowImages] boolValue];
        [_handleOutFileTypeButton setEnabled:NO];
        self.handlesOutFileType = [[profileConfiguration objectForKey:TSPlasterOutAllowFiles] boolValue];
        
        NSString *mode = [profileConfiguration objectForKey:TSPlasterMode];
        [self.plasterLocationSelectionMatrix setEnabled:YES];
        if ([mode isEqualToString:TSPlasterModePasteboard]) {
            [self enablePasteboardMode];
        } else if ([mode isEqualToString:TSPlasterModeFile]) {
            [self enableFileMode];
        }
        self.plasterFolder = [profileConfiguration objectForKey:TSPlasterFolderPath];
        if ([self.plasterFolder isEqualToString:@""]) {
            self.plasterFolder = NSHomeDirectory();
        }
        
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
            
            [self willChangeValueForKey:@"plasterFolder"];
            self.plasterFolder = path;
            [self didChangeValueForKey:@"plasterFolder"];
            [_mutableProfileConfiguration setObject:self.plasterMode forKey:TSPlasterMode];
            if (![self.plasterFolder isEqualToString:@""]) {
                [_mutableProfileConfiguration setObject:self.plasterFolder forKey:TSPlasterFolderPath];
            } else {
                [_mutableProfileConfiguration setObject:NSHomeDirectory() forKey:TSPlasterFolderPath];
            }
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

- (void)dealloc {
    _mutableProfileConfiguration = nil;
    
    [_plasterFolder release];
    [_plasterMode release];
    
    [super dealloc];
}


@end
