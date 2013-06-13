//
//  TSAppDelegate.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (assign) IBOutlet NSMenu *plasterMenu;
@property (assign) IBOutlet NSMenuItem *joinMenuItem;
@property (assign) IBOutlet NSMenuItem *peersMenuItem;

@property (assign) IBOutlet NSMenuItem *startStopPlasterMenuItem;

@property (assign) IBOutlet NSPanel *joinSessionHUD;
@property (assign) IBOutlet NSTextField *joinSessionKeyTextField;

@property (readwrite, atomic, copy) NSString *sessionKey;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showJoinHUD:(id)sender;

- (IBAction)cancelJoinSession:(id)sender;
- (IBAction)joinSession:(id)sender;
- (IBAction)createNewSession:(id)sender;
- (IBAction)startStopPlaster:(id)sender;

@end
