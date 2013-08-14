//
//  TSLNewSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLNewSessionViewController.h"
#import "TSLProfilesViewController.h"
#import "TSLClientIdentifier.h"
#import "TSLPlasterAppDelegate.h"
#import "TSLPlasterGlobals.h"
#import "TSLPlasterProfilesController.h"
#import "TSLSessionViewController.h"

@interface TSLNewSessionViewController () {
    TSLPlasterProfilesController *_userProfileDicatator;    
    NSArray *_rowsInSection;
    NSArray *_sectionHeaders;
}

@property (strong, readwrite) NSDictionary *profile;
@property (copy, readwrite) NSString *sessionKey;

@end

@implementation TSLNewSessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _userProfileDicatator = [[TSLPlasterProfilesController alloc] init];
        DLog(@"Initializing rows and section headers...");
        _rowsInSection = [@[@1, @1, @2, @2] retain];
        _sectionHeaders = [@[@"Profile", @"Notifications", @"Incoming Plasters", @"Outgoing Plasters"] retain];
        _profile = nil;
        _sessionKey = nil;

    }
    return self;
}

- (id)initWithProfileName:(NSString *)name {
    self = [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
    if (self) {
        self.profileName = name;
    }
    
    return self;
}

- (id)initWithProfile:(NSDictionary *)aProfile sessionKey:(NSString *)key editing:(BOOL)editing {
    self = [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
    if (self) {
        self.editProfile = editing;
        self.sessionKey = key;
        self.profile = aProfile;
    }
    
    return self;
}

- (id)initWithProfileName:(NSString *)aProfileName sessionKey:(NSString *)key editing:(BOOL)editing {
    self = [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
    if (self) {
        self.editProfile = editing;
        self.sessionKey = key;
        self.profileName = aProfileName;
        NSMutableDictionary *tempProfile = [NSMutableDictionary dictionary];
        [tempProfile setObject:self.profileName forKey:TSPlasterProfileName];
        [tempProfile setObject:@YES forKey:TSPlasterNotifyAll];
        [tempProfile setObject:@YES forKey:TSPlasterAllowText];
        [tempProfile setObject:@YES forKey:TSPlasterAllowImages];
        [tempProfile setObject:@YES forKey:TSPlasterOutAllowText];
        [tempProfile setObject:@YES forKey:TSPlasterOutAllowImages];
        
        // Other iOS defaults
        [tempProfile setObject:@NO forKey:TSPlasterAllowFiles];
        [tempProfile setObject:@NO forKey:TSPlasterOutAllowFiles];
        [tempProfile setObject:TSPlasterModePasteboard forKey:TSPlasterMode];
        
        self.profile = tempProfile;
    }
    
    return self;
}

- (id)init {
    return [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
}

- (void)viewDidLoad {
    DLog(@"View is loading!!!");
    [super viewDidLoad];
    // set up navigation bar items
    UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
                                                                                     action:@selector(done:)] autorelease];
    UIBarButtonItem *cancelButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
                                                                                       action:@selector(cancel:)] autorelease];
    
    self.navigationItem.rightBarButtonItems = @[doneButtonItem, cancelButtonItem];
    
    if (!self.editProfile) {
        self.sessionKey = [TSLClientIdentifier createUUID];
    }
    if (_profile) {
        self.profileName = [_profile objectForKey:TSPlasterProfileName];
        self.notificationsSwitch.on = [[_profile objectForKey:TSPlasterNotifyAll] boolValue];
        self.allowIncomingTextSwitch.on = [[_profile objectForKey:TSPlasterAllowText] boolValue];
        self.allowIncomingImagesSwitch.on = [[_profile objectForKey:TSPlasterAllowImages] boolValue];
        self.allowOutgoingTextSwitch.on = [[_profile objectForKey:TSPlasterOutAllowText] boolValue];
        self.allowOutgoingImagesSwitch.on = [[_profile objectForKey:TSPlasterOutAllowImages] boolValue];
    }
    self.profileNameLabel.text = self.profileName;
}

#pragma mark UITableView data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Section 0 : Profile name
    // Section 1 : Notification
    // Section 2 : Incoming plaster configuration
    // Section 3 : Outgoing plaster configuration
    return [_rowsInSection[section] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case 0:
            //DLog(@"Requesting profile name cell..");
            cell = self.profileNameCell;
            break;
        case 1:
            //DLog(@"Requesting notification cell..");
            cell = self.notificationCell;
            break;
        case 2:
            if (indexPath.row == 0) {
                cell = self.allowIncomingTextCell;
            } else if (indexPath.row == 1) {
                cell = self.allowIncomingImagesCell;
            }
            break;
        case 3:
            if (indexPath.row == 0) {
                cell = self.allowOutgoingTextCell;
            } else if (indexPath.row == 1) {
                cell = self.allowOutgoingImagesCell;
            }
            break;
        default:
            cell = self.notificationCell;
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    //DLog(@"Requesting title for header in section : %d", section);
    return _sectionHeaders[section];
}


#pragma mark UITableView delegate methods


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Handles for Done and Cancel nav bar buttons

- (void)done:(id)sender {
    DLog(@"Saving new profile configuration.");
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableDictionary *profile = [[NSMutableDictionary alloc] init];
    [profile setObject:self.profileName forKey:TSPlasterProfileName];
    [profile setObject:[NSNumber numberWithBool:self.notificationsSwitch.on] forKey:TSPlasterNotifyAll];
    [profile setObject:[NSNumber numberWithBool:self.allowIncomingTextSwitch.on] forKey:TSPlasterAllowText];
    [profile setObject:[NSNumber numberWithBool:self.allowIncomingImagesSwitch.on] forKey:TSPlasterAllowImages];
    [profile setObject:[NSNumber numberWithBool:self.allowOutgoingTextSwitch.on] forKey:TSPlasterOutAllowText];
    [profile setObject:[NSNumber numberWithBool:self.allowOutgoingImagesSwitch.on] forKey:TSPlasterOutAllowImages];
    
    // Other iOS defaults
    [profile setObject:@NO forKey:TSPlasterAllowFiles];
    [profile setObject:@NO forKey:TSPlasterOutAllowFiles];
    [profile setObject:TSPlasterModePasteboard forKey:TSPlasterMode];
    
    DLog(@"Saving profile with values : %@", profile);
    [_userProfileDicatator addProfile:profile withKey:self.sessionKey];
    
    [delegate.navController popViewControllerAnimated:NO];
    TSLSessionViewController *sessionViewController = [[[TSLSessionViewController alloc] initWithProfile:profile
                                                                                              sessionKey:self.sessionKey] autorelease];
    [delegate.navController pushViewController:sessionViewController animated:YES];
    [profile release];    
}

- (void)cancel:(id)sender {
    DLog(@"Cancelling new profile configuration.");
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.navController popViewControllerAnimated:YES];
}

- (void)dealloc {
    [_sessionConfigurationTableView release];
    [_notificationCell release];
    [_allowIncomingTextCell release];
    [_allowIncomingImagesCell release];
    [_allowOutgoingTextCell release];
    [_allowOutgoingImagesCell release];
    
    [_rowsInSection release];
    [_sectionHeaders release];
    [_profileNameCell release];
    [_profileNameLabel release];
    [_notificationsSwitch release];
    [_allowIncomingTextSwitch release];
    [_allowIncomingImagesSwitch release];
    [_allowOutgoingTextSwitch release];
    [_allowOutgoingImagesSwitch release];
    [_profile release];
    [super dealloc];
}
@end
