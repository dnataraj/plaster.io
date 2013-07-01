//
//  TSAppDelegate.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (assign) IBOutlet NSLayoutConstraint *customViewVerticalLayoutConstraint;

@property (assign) IBOutlet NSMenu *plasterMenu;
@property (assign) IBOutlet NSMenuItem *joinMenuItem;
@property (assign) IBOutlet NSMenuItem *freshSessionMenuItem;
@property (assign) IBOutlet NSMenuItem *saveAsMenuItem;
@property (assign) IBOutlet NSMenuItem *startWithProfileMenuItem;
@property (assign) IBOutlet NSMenuItem *stopMenuItem;
@property (assign) IBOutlet NSMenuItem *passcodeMenuItem;

@property (assign) IBOutlet NSMenuItem *peersMenuItem;
@property (assign) IBOutlet NSMenuItem *preferencesMenuItem;

// Panel and outlets for "join session"
@property (assign) IBOutlet NSPanel *joinSessionHUD;
@property (assign) IBOutlet NSTextField *joinSessionKeyTextField;
@property (assign) IBOutlet NSButton *okButton;
@property (assign) IBOutlet NSButton *configureJoinSessionButton;
@property (assign) IBOutlet NSView *joinProfileConfigurationView;

// Panel and outlets for "new session"
@property (assign) IBOutlet NSPanel *freshSessionHUD;
@property (assign) IBOutlet NSTextField *freshSessionKeyTextField;
@property (assign) IBOutlet NSView *freshProfileConfigurationView;


// Panel and outlet for "save profile"
@property (assign) IBOutlet NSPanel *saveProfileHUD;
@property (assign) IBOutlet NSTextField *profileNameTextField;
@property (assign) IBOutlet NSButton *saveProfileButton;

@property (readwrite, atomic, copy) NSString *sessionKey;
@property (readwrite, atomic, copy) NSString *currentProfileName;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (IBAction)showJoinHUD:(id)sender;
- (IBAction)joinSession:(id)sender;
- (IBAction)cancelJoinSession:(id)sender;

- (IBAction)freshSession:(id)sender;
- (IBAction)startFreshSession:(id)sender;

- (IBAction)showSaveProfileHUD:(id)sender;
- (IBAction)saveProfile:(id)sender;
- (IBAction)cancelSaveProfile:(id)sender;

- (IBAction)pasteCurrentPasscode:(id)sender;

@end
