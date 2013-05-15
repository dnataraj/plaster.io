//
//  TSAppDelegate.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *plasterMenu;
@property (weak) IBOutlet NSMenuItem *stopMenuItem;
@property (weak) IBOutlet NSMenuItem *startMenuItem;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;


@end
