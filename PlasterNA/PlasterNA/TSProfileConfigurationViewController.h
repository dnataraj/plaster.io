//
//  TSProfileConfigurationViewController.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/26/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSProfileConfigurationViewController : NSViewController

@property (assign) IBOutlet NSTabView *profileConfigurationTabView;

@property (assign) IBOutlet NSButton *handleInTextTypeButton;
@property (assign) IBOutlet NSButton *handleInImageTypeButton;
@property (assign) IBOutlet NSButton *handleInFileTypeButton;

@property (assign) IBOutlet NSButton *handleOutTextTypeButton;
@property (assign) IBOutlet NSButton *handleOutImageTypeButton;
@property (assign) IBOutlet NSButton *handleOutFileTypeButton;

@property (assign) IBOutlet NSMatrix *plasterLocationSelectionMatrix;
@property (assign) IBOutlet NSTextField *plasterFolderLocationTextField;
@property (assign) IBOutlet NSButton *plasterFolderLocationBrowseButton;

@property (assign) IBOutlet NSButton *shouldNotifyJoinsButton;
@property (assign) IBOutlet NSButton *shouldNotifyDeparturesButton;
@property (assign) IBOutlet NSButton *shouldNotifyPlastersButton;

@property (assign) IBOutlet NSButton *shouldNotifySendsButton;
@property (assign) IBOutlet NSButton *allowCMDCButton;


@property (copy) NSString *plasterFolder;
@property (copy) NSString *plasterMode;
@property (readwrite) BOOL handlesInTextType, handlesInImageType, handlesInFileType;
@property (readwrite) BOOL handlesOutTextType, handlesOutImageType, handlesOutFileType;
@property (readwrite) BOOL shouldNotifyJoins, shouldNotifyDepartures, shouldNotifyPlasters, shouldNotifySends, allowCMDC;

- (IBAction)plasterFolderLocationBrowse:(id)sender;
- (IBAction)switchPlasterDestination:(id)sender;

- (void)disableProfileConfiguration;
- (NSDictionary *)getProfileConfiguration;
- (void)configureWithProfile:(NSMutableDictionary *)profileConfiguration;

@end
