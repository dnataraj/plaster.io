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
#import "TSLUserProfileDictator.h"

@interface TSLNewSessionViewController () {
    TSLUserProfileDictator *_userProfileDicatator;    
    NSArray *_rowsInSection;
    NSArray *_sectionHeaders;
}

@property (copy, readwrite) NSString *sessionKey;

@end

@implementation TSLNewSessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _userProfileDicatator = [[TSLUserProfileDictator alloc] init];
        DLog(@"Initializing rows and section headers...");
        _rowsInSection = [@[@1, @1, @2, @2] retain];
        _sectionHeaders = [@[@"Profile", @"Notifications", @"Incoming Plasters", @"Outgoing Plasters"] retain];
        
        self.shouldNotify = YES;
        self.allowIncomingText = YES;
        self.allowIncomingImages = YES;
        self.allowOutgoingText = YES;
        self.allowOutgoingImages = YES;
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

- (id)initWithProfile:(NSDictionary *)profile sessionKey:(NSString *)key editing:(BOOL)editing {
    self = [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
    if (self) {
        self.editProfile = editing;
        self.sessionKey = key;
        self.profileName = [profile objectForKey:TSPlasterProfileName];
        self.notificationsSwitch.on = [[profile objectForKey:TSPlasterNotifyAll] boolValue];
        self.allowIncomingTextSwitch.on = [[profile objectForKey:TSPlasterAllowText] boolValue];
        self.allowIncomingImagesSwitch.on = [[profile objectForKey:TSPlasterAllowImages] boolValue];
        self.allowOutgoingTextSwitch.on = [[profile objectForKey:TSPlasterOutAllowText] boolValue];
        self.allowOutgoingImagesSwitch.on = [[profile objectForKey:TSPlasterOutAllowImages] boolValue];
    }
    
    return self;
}

- (id)init {
    return [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // set up navigation bar items
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItems = @[doneButtonItem, cancelButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.editProfile) {
        self.sessionKey = [TSLClientIdentifier createUUID];
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
    DLog(@"Requesting title for header in section : %d", section);
    return _sectionHeaders[section];
}


#pragma mark UITableView delegate methods


#pragma mark target-action for UI

- (IBAction)switchNotifications:(id)sender {
    UISwitch *notificationSwitch = (UISwitch *)sender;
    self.shouldNotify = notificationSwitch.on;
    DLog(@"Swittching notify all to : %i", self.shouldNotify);
}

- (IBAction)switchAllowIncomingText:(id)sender {
    UISwitch *incomingTextSwitch = (UISwitch *)sender;
    self.allowIncomingText = incomingTextSwitch.on;
}

- (IBAction)switchAllowIncomingImages:(id)sender {
    UISwitch *incomingImagesSwitch = (UISwitch *)sender;
    self.allowIncomingImages = incomingImagesSwitch.on;
}

- (IBAction)switchAllowOutgoingText:(id)sender {
    UISwitch *outgoingTextSwitch = (UISwitch *)sender;
    self.allowOutgoingText = outgoingTextSwitch.on;
}

- (IBAction)switchAllowOutgoingImages:(id)sender {
    UISwitch *outgoingImagesSwitch = (UISwitch *)sender;
    self.allowOutgoingImages = outgoingImagesSwitch.on;
}

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
    [profile setObject:[NSNumber numberWithBool:self.shouldNotify] forKey:TSPlasterNotifyAll];
    [profile setObject:[NSNumber numberWithBool:self.allowIncomingText] forKey:TSPlasterAllowText];
    [profile setObject:[NSNumber numberWithBool:self.allowIncomingImages] forKey:TSPlasterAllowImages];
    [profile setObject:[NSNumber numberWithBool:self.allowOutgoingText] forKey:TSPlasterOutAllowText];
    [profile setObject:[NSNumber numberWithBool:self.allowOutgoingImages] forKey:TSPlasterOutAllowImages];
    
    DLog(@"Saving profile with values : %@", profile);
    [_userProfileDicatator addProfile:profile withKey:self.sessionKey];
    [profile release];
    
    [delegate.navController popViewControllerAnimated:YES];
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
    [super dealloc];
}
@end
