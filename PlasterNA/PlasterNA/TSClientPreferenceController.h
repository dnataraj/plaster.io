//
//  TSClientPreferenceController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProfileConfigurationViewController.h"

@interface TSClientPreferenceController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSTextField *deviceNameTextField;

@property (assign) IBOutlet NSTableView *profileListTableView;

@property (assign) IBOutlet NSTextField *sessionKeyLabelField;

@property (assign) IBOutlet NSView *profileConfigurationView;
@property (retain) TSProfileConfigurationViewController *profileViewController;

@property (retain) NSString *deviceName;

- (IBAction)deleteProfile:(id)sender;

- (IBAction)cancelPreferences:(id)sender;
- (IBAction)saveAndClosePreferences:(id)sender;


@end
