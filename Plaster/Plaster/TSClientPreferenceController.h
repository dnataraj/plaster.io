//
//  TSClientPreferenceController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSClientPreferenceController : NSWindowController <NSWindowDelegate>

@property (weak) IBOutlet NSTextField *spiderKeyTextField;
@property (weak) IBOutlet NSButton *handleTextTypeButton;
@property (weak) IBOutlet NSButton *handleImageTypeButton;

@property (readonly, copy) NSString *spiderKey;
@property (readwrite) BOOL handlesTextType, handlesImageType;

- (IBAction)generateSpiderKey:(id)sender;

@end
