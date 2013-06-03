//
//  TSClientPreferenceController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSClientPreferenceController : NSWindowController <NSWindowDelegate>

@property (assign) IBOutlet NSTextField *sessionIDTextField;
@property (assign) IBOutlet NSButton *handleTextTypeButton;
@property (assign) IBOutlet NSButton *handleImageTypeButton;

@property (readonly, retain) NSString *sessionID;
@property (readwrite) BOOL handlesTextType, handlesImageType;

- (IBAction)generateSessionID:(id)sender;

@end
