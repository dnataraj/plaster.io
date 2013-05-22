//
//  TSClientPreferenceController.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/22/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSClientPreferenceController.h"
#import "TSClientIdentifier.h"

@interface TSClientPreferenceController ()

@property (readwrite, copy) NSString *spiderKey;

@end

@implementation TSClientPreferenceController {
    NSUserDefaults *_userDefaults;
}

- (id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _spiderKey = [_userDefaults stringForKey:@"plaster-spider-key"];
        _handlesTextType = [_userDefaults boolForKey:@"plaster-allow-text"];
        _handlesImageType = [_userDefaults boolForKey:@"plaster-allow-images"];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Saving user preferences...");
    [_userDefaults setObject:[self spiderKey] forKey:@"plaster-spider-key"];
    [_userDefaults setBool:[self handlesTextType] forKey:@"plaster-allow-text"];
    [_userDefaults setBool:[self handlesImageType] forKey:@"plaster-allow-images"];
}

/*
- (void)windowDidLoad {
    [self.spiderKeyTextField setValue:[self spiderKey]];
    [self.handleTextTypeButton setState:[self handlesTextType]];
    [self.handleImageTypeButton setState:[self handlesImageType]];
}
*/

- (IBAction)generateSpiderKey:(id)sender {
    NSLog(@"Generating new spider key...");
    [self willChangeValueForKey:@"spiderKey"];
    self.spiderKey = [TSClientIdentifier createUUID];
    [self didChangeValueForKey:@"spiderKey"];
}

@end
