//
//  TSAppDelegate.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSMenu *plasterMenu;
@property (assign) IBOutlet NSMenuItem *stopMenuItem;
@property (assign) IBOutlet NSMenuItem *startMenuItem;
@property (assign) IBOutlet NSMenuItem *disconnectMenuItem;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)showPreferences:(id)sender;


@end
