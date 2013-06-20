//
//  TSClientPreferenceController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSClientPreferenceController : NSWindowController <NSWindowDelegate>

@property (assign) IBOutlet NSTextField *deviceNameTextField;
@property (assign) IBOutlet NSButton *handleTextTypeButton;
@property (assign) IBOutlet NSButton *handleImageTypeButton;
@property (assign) IBOutlet NSButton *handleFileTypeButton;
@property (assign) IBOutlet NSTextField *sessionKeyLabelField;

@property (assign) IBOutlet NSButton *shouldNotifyJoinsButton;
@property (assign) IBOutlet NSButton *shouldNotifyDeparturesButton;
@property (assign) IBOutlet NSButton *shouldNotifyPlastersButton;
@property (assign) IBOutlet NSMatrix *plasterLocationMatrix;
@property (assign) IBOutlet NSTextField *plasterLocationFileTextField;
@property (assign) IBOutlet NSButton *browseButton;

@property (readonly) NSString *sessionKey;
@property (retain) NSString *plasterMode, *deviceName, *plasterFolder;
@property (readwrite) BOOL handlesTextType, handlesImageType, handlesFileType;
@property (readwrite) BOOL shouldNotifyJoins, shouldNotifyDepartures, shouldNotifyPlasters;

- (IBAction)browse:(id)sender;
- (IBAction)switchPlasterDestination:(id)sender;

@end
