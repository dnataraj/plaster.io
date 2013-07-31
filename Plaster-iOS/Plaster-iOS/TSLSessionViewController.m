//
//  TSLSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/30/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLSessionViewController.h"
#import "TSLPlasterGlobals.h"
#import "TSLPlasterController.h"  
#import "TSLRedisController.h"
#import "TSLPlasterAppDelegate.h"

@interface TSLSessionViewController () 
@end

@implementation TSLSessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithProfile:(NSDictionary *)aProfile sessionKey:(NSString *)key {
    self = [self initWithNibName:@"TSLSessionViewController" bundle:nil];
    if (self) {
        self.sessionKey = key;
        self.profile = aProfile;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    DLog(@"Loading session start view...");
    self.profileNameLabel.text = [self.profile objectForKey:TSPlasterProfileName];
    self.sessionStartSwitch.on = NO;
    self.on = NO;
    self.sessionKeyTextView.text = self.sessionKey;
    [self.sessionKeyTextView becomeFirstResponder];
    self.sessionKeyTextView.selectedRange = NSMakeRange(0, [self.sessionKey length]);
    
    [UIPasteboard generalPasteboard].string = self.sessionKey;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.sessionStartSwitch.on) {
        DLog(@"View disappearing, switching of plaster..");
        self.sessionStartSwitch.on = NO;
        self.on = NO;
    }
}

- (IBAction)toggleSessionState:(id)sender {
    UIApplication *application = [UIApplication sharedApplication];
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.on = ((UISwitch *)sender).on;
    
    __block TSLPlasterController *__plasterController = delegate.plasterController;
    __block UIBackgroundTaskIdentifier __plasterBgTask = UIBackgroundTaskInvalid;
    
    if (((UISwitch *)sender).on == YES) {
        DLog(@"Starting session : %@", self.profileNameLabel.text);
        // TODO : Force application to enter background. ??
        
        // Start plaster and register as a background task to handle suspended state
        __block TSLSessionViewController *__sessionVC = self;
        [__plasterController setSessionKey:self.sessionKey];
        [__plasterController setSessionProfile:self.profile];
        [__plasterController setAlias:[[UIDevice currentDevice] name]];
        
        __plasterBgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            DLog(@"Plaster background monitor was stiatched. Cleaning up...");
            [__plasterController stop];
            __plasterController = nil;
            __sessionVC.on = NO;
            DLog(@"Ending plaster monitor background task registration.");
            [application endBackgroundTask:__plasterBgTask];
            __plasterBgTask = UIBackgroundTaskInvalid;
        }];
        
        if (__plasterBgTask == UIBackgroundTaskInvalid) {
            DLog(@"iOS Kernel refuses to create plaster background monitor. Stiatched.");
            return;
        }
        
        [__plasterController start];
    } else {
        DLog(@"Stopping session : %@", self.profileNameLabel.text);
        if ([__plasterController running]) {
            DLog(@"Stopping a running session.");
            [__plasterController stop];
            if (__plasterBgTask != UIBackgroundTaskInvalid) {
                DLog(@"Ending plaster monitor background task registration.");
                [application endBackgroundTask:__plasterBgTask];
            }
        }
    }
    
    return;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    DLog(@"Deallocing!");
    [_sessionKey release];
    [_profile release];
    [_sessionStartSwitch release];
    [_profileNameLabel release];

    [_sessionKeyTextView release];
    [super dealloc];
}

@end
