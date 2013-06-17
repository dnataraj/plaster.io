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

@property (readonly, copy) NSString *sessionKey, *deviceName;
@property (readwrite) BOOL handlesTextType, handlesImageType, handlesFileType;
@property (readwrite) BOOL shouldNotifyJoins, shouldNotifyDepartures, shouldNotifyPlasters;


@end
