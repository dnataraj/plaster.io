//
//  TSSClientStartPanelController.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSClientStartPanelController : NSWindowController

@property (weak) IBOutlet NSTextField *sessionKeyTextField;
@property (readwrite, copy) NSString *sessionKey;

- (IBAction)useSessionKey:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface TSClientStartPanelValueTransformer : NSValueTransformer

@end
