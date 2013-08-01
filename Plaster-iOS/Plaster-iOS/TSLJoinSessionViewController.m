//
//  TSLJoinSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/1/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLJoinSessionViewController.h"
#import "TSLPlasterAppDelegate.h"
#import "TSLNewSessionViewController.h"

@interface TSLJoinSessionViewController ()

@end

@implementation TSLJoinSessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithProfileName:(NSString *)name {
    self = [self initWithNibName:@"TSLJoinSessionViewController" bundle:nil];
    if (self) {
        self.profileName = name;
    }
    
    return self;
}

- (id)init {
    return [self initWithNibName:@"TSLJoinSessionViewController" bundle:nil];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.joinProfileNameLabel.text = self.profileName;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinSession:(id)sender {
    NSString *joinSessionKey = self.sessionKeyEntryTextView.text;
    if ([joinSessionKey length] == 36) {
        DLog(@"Obtained valid session key : %@", joinSessionKey);
    }

    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.navController popViewControllerAnimated:NO];
    TSLNewSessionViewController *newSessionViewController = [[[TSLNewSessionViewController alloc] initWithProfileName:self.profileName
                                                                                                           sessionKey:joinSessionKey
                                                                                                              editing:YES] autorelease];
    [delegate.navController pushViewController:newSessionViewController animated:YES];
}

- (IBAction)joinWithDefaults:(id)sender {
    NSString *joinSessionKey = self.sessionKeyEntryTextView.text;
    if ([joinSessionKey length] == 36) {
        DLog(@"Obtained valid session key : %@", joinSessionKey);
    }
    
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.navController popViewControllerAnimated:NO];
    TSLNewSessionViewController *newSessionViewController = [[[TSLNewSessionViewController alloc] initWithProfileName:self.profileName
                                                                                                           sessionKey:joinSessionKey
                                                                                                              editing:YES] autorelease];
    [newSessionViewController done:self];
}

- (void)dealloc {
    [_profileName release];
    [_joinProfileNameLabel release];
    [_sessionKeyEntryTextView release];
    [super dealloc];
}

@end
