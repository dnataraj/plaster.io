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
@property (assign) IBOutlet NSTextField *sessionKeyLabelField;


@property (readonly, copy) NSString *sessionKey, *deviceName;
@property (readwrite) BOOL handlesTextType, handlesImageType;

@end
