//
//  TSSClientStartPanelController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSClientStartPanelController.h"

@interface TSClientStartPanelController ()

@end

@implementation TSClientStartPanelController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)init {
    self = [super initWithWindowNibName:@"TSClientStartPanel"];
    if (self) {
        TSClientStartPanelValueTransformer *transformer = [[TSClientStartPanelValueTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"TSClientStartPanelValueTransformer"];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    /*
    [_sharedKeyTextField setTextColor:[NSColor disabledControlTextColor]];
    NSString *initialSharedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"plaster-spider-key"];
    [_sharedKeyTextField setStringValue:initialSharedKey];
    */
}

- (IBAction)useSharedKey:(id)sender {
    NSLog(@"Registering key [%@] as the shared spider key.", [[self sharedKeyTextField] stringValue]);
    [[NSUserDefaults standardUserDefaults] setObject:[[self sharedKeyTextField] stringValue] forKey:@"plaster-spider-key"];
    [self markInitComplete];
    [self close];
}

- (IBAction)cancel:(id)sender {
    NSLog(@"User has decided to use internal client key. Dismissing window.");
    [self markInitComplete];
    [self close];
}

- (void)markInitComplete {
    NSLog(@"Marking first time usage as complete...");
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"plaster-init"];
    [NSApp stopModal];    
}

@end

@implementation TSClientStartPanelValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    }
    
    if ([value respondsToSelector:@selector(length)]) {
        BOOL canOK = ([value length] == 36);
        return [NSNumber numberWithBool:canOK];
    }
    
    return [NSNumber numberWithBool:NO];
}


@end


