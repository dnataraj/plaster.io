//
//  TSLSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLProfilesViewController.h"
#import "TSLPlasterAppDelegate.h"
#import "TSLNewSessionViewController.h"
#import "TSLModalAlertDelegate.h"
#import "TSLPlasterGlobals.h"
#import "TSLSessionViewController.h"
#import "TSLJoinSessionViewController.h"
#import "TSLProfileViewCell.h"
#import "TSLPlasterProfilesController.h"
#import "TSLPlasterProfile.h"
#import "TSLPlasterController.h"

#define DegreesToRadians(x) (M_PI * x / 180.0)

@interface TSLProfilesViewController () {
    TSLPlasterProfilesController *_plasterProfilesController;
    NSMutableArray *_displayProfiles;
    NSMutableArray *_displaySessionKeys;
    //__block UIBackgroundTaskIdentifier __plasterBgTask;
    UIButton *_sessionDetailsButton;
}

@end

@implementation TSLProfilesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _plasterProfilesController = [[TSLPlasterProfilesController alloc] init];
        _displayProfiles = nil;
        _displaySessionKeys = nil;
        //__plasterBgTask = UIBackgroundTaskInvalid;
        _sessionDetailsButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
        CGAffineTransform rotationTransform = CGAffineTransformIdentity;
        rotationTransform = CGAffineTransformRotate(rotationTransform, DegreesToRadians(90));
        _sessionDetailsButton.transform = rotationTransform;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Profiles";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Register our custom tableview cell class
    //r[self.profilesTableView registerClass:[TSLProfileViewCell class] forCellReuseIdentifier:@"TSLProfileViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resetDisplayKeys];    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing != self.editing) {
        [super setEditing:editing animated:animated];
        [self.profilesTableView setEditing:editing animated:animated];
        
        NSMutableArray *indices = [[NSMutableArray alloc] init];
        for (int i=0; i < self.numberOfProfiles; i++) {
            [indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        NSArray *lastIndex = @[[NSIndexPath indexPathForRow:self.numberOfProfiles inSection:0], [NSIndexPath indexPathForRow:(self.numberOfProfiles + 1) inSection:0]];
        if (editing == YES) {
            for (int i = 0; i < self.numberOfProfiles; i++) {
                UITableViewCell *cell = [self.profilesTableView cellForRowAtIndexPath:indices[i]];
                DLog(@"Setting accessory type for cell in Edit mode...");
                [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            [self.profilesTableView deleteRowsAtIndexPaths:lastIndex withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            for (int i = 0; i < self.numberOfProfiles; i++) {
                UITableViewCell *cell = [self.profilesTableView cellForRowAtIndexPath:indices[i]];
                [cell setEditingAccessoryType:UITableViewCellAccessoryNone];
            }
            
            [self.profilesTableView insertRowsAtIndexPaths:lastIndex withRowAnimation:UITableViewRowAnimationLeft];
        }
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetDisplayKeys {
    [_displayProfiles release];
    _displayProfiles = nil;
    _displayProfiles = [[NSMutableArray alloc] init];
    
    [_displaySessionKeys release];
    _displaySessionKeys = nil;
    _displaySessionKeys = [[NSMutableArray alloc] init];
    
    // Obtain TSLPlasterProfile list
    NSDictionary *profiles = [_plasterProfilesController profiles];
    for (NSString *key in [profiles keyEnumerator]) {
        TSLPlasterProfile *plasterProfile = [profiles objectForKey:key];
        DLog(@"Found profile : %@", plasterProfile);
        
        [_displayProfiles addObject:[plasterProfile.profile objectForKey:TSPlasterProfileName]];
        [_displaySessionKeys addObject:key];
    }
    
    DLog(@"Found profiles : %@", _displayProfiles);
    self.numberOfProfiles = [_displayProfiles count];
    DLog(@"Found session keys : %@", _displaySessionKeys);
    
    [_displayProfiles addObjectsFromArray:@[@"New Plaster session", @"Join a session..."]];
    [self.profilesTableView reloadData];
}

#pragma mark Action methods

- (void)startPlasterWithProfile:(TSLPlasterProfile *)profile  {
    // "auto-save" current session key for post-crash cleanup (if any)
    [_plasterProfilesController saveCurrentSessionWithKey:profile.sessionKey];
    if ([profile controlPlaster:TSLPlasterStart] != EXIT_SUCCESS) {
        DLog(@"Starting plaster failed. Alerting user.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Plaster is unable to start."
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

    return;
}

- (void)stopPlasterWithProfile:(TSLPlasterProfile *)profile  {
    // "auto-save" current session key for post-crash cleanup (if any)
    [_plasterProfilesController saveCurrentSessionWithKey:profile.sessionKey];
    [profile controlPlaster:TSLPlasterStop];
    
    return;
}


#pragma mark UITableView data source methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO : Obtain stored profiles from user preferences. (allow user to delete these)
    if (self.editing) {
        return self.numberOfProfiles;
    }
    return [_displayProfiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row < self.numberOfProfiles) {
        TSLPlasterProfile *plasterProfile = [_plasterProfilesController.profiles objectForKey:_displaySessionKeys[indexPath.row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"TSLProfileViewCell"];
        if (!cell) {
            DLog(@"Initializing cell at index path : %@", indexPath);
            cell = [[[TSLProfileViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TSLProfileViewCell"] autorelease];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
        
        NSLog(@"Obtained cell type : %@", cell);
        if ([plasterProfile state] == TSLPlasterRunning) {
            //cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"[Running with %ld peers...]", (unsigned long)[[plasterProfile peers] count]];
        } else {
            //cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = @"[Stopped]";
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NewJoinCell"];
        if (!cell) {
            NSLog(@"TSL: Session View Controller : Initializing cell at index path : %@", indexPath);
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NewJoinCell"] autorelease];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = _displayProfiles[indexPath.row];
    //DLog(@"Returning cell for index row : %d with label : %@", indexPath.row, _displayProfiles[indexPath.row]);
    
    return cell;
}

#pragma mark UITableView delegate methods

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"Attempting to delete row with index path : %@", indexPath);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_displayProfiles removeObjectAtIndex:indexPath.row];
        [_plasterProfilesController removeProfileWithKey:_displaySessionKeys[indexPath.row]];
        [_displaySessionKeys removeObjectAtIndex:indexPath.row];
        self.numberOfProfiles = self.numberOfProfiles - 1;
        DLog(@"Number of profiles is now : %d", self.numberOfProfiles);
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"Selected row at index path : %@", indexPath);
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // For starting a new session and joining another session
    if (indexPath.row == ([_displayProfiles count] - 2)) {
        // Ask the user to set a valid user name and then proceed to the profile configuration view.
        NSString *profileName = [self alertForProfileName:self];
        DLog(@"Obtained profile name : %@", profileName);
        if (profileName) {
            DLog(@"Pushing new session view controller onto the nav...");
            TSLNewSessionViewController *newSessionViewController = [[[TSLNewSessionViewController alloc] initWithProfileName:profileName] autorelease];
            [delegate.navController pushViewController:newSessionViewController animated:YES];
        } else {
            DLog(@"Will not load profle configuration view without a valid profile name.");
        }
    } else if (indexPath.row == ([_displayProfiles count] - 1)) {
        // Ask the user to set a valid user name and then proceed to the join session view.
        NSString *profileName = [self alertForProfileName:self];
        DLog(@"Obtained profile name : %@", profileName);
        if (profileName) {
            DLog(@"Pushing join session view controller onto the nav...");
            TSLJoinSessionViewController *joinSessionViewController = [[[TSLJoinSessionViewController alloc]
                                                                        initWithProfileName:profileName] autorelease];
            [delegate.navController pushViewController:joinSessionViewController animated:YES];
        } else {
            DLog(@"Will not load profle configuration view without a valid profile name.");
        }
    } else {
        TSLPlasterProfile *plasterProfile = [[_plasterProfilesController profiles] objectForKey:_displaySessionKeys[indexPath.row]];
        DLog(@"Obtained stored profile : %@", plasterProfile);
        // For re-configuring existing sessions in edit mode
        if (self.editing) {
            DLog(@"Pushing new session view controller onto the nav for editing existing profiles...");
            TSLNewSessionViewController *newSessionViewController = [[[TSLNewSessionViewController alloc] initWithProfile:plasterProfile.profile
                                                                                                               sessionKey:_displaySessionKeys[indexPath.row]
                                                                                                                  editing:self.editing] autorelease];
            [delegate.navController pushViewController:newSessionViewController animated:YES];
        } else {
            TSLProfileViewCell *cell = (TSLProfileViewCell *)[self.profilesTableView cellForRowAtIndexPath:indexPath];
            // User taps a session to start/stop it
            if ([plasterProfile state] == TSLPlasterRunning) {
                DLog(@"User is stopping a running session...");
                [self stopPlasterWithProfile:plasterProfile];
                cell.detailTextLabel.text = @"[Stopped]";
                [cell.plasterStartingIndicator stopAnimating];
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                DLog(@"Starting session with key : %@ and cell : %@", plasterProfile.sessionKey, cell);
                [self startPlasterWithProfile:plasterProfile];
                cell.detailTextLabel.text = [[NSString stringWithFormat:@"%ld peers connected.",
                                             (unsigned long)[[plasterProfile peers] count]] retain];
                [cell.plasterStartingIndicator stopAnimating];
                cell.accessoryView = nil;
                cell.accessoryView = _sessionDetailsButton;
            }

            /*
            TSLSessionViewController *sessionViewController = [[[TSLSessionViewController alloc] initWithProfile:plasterProfile.profile
                                                                                                      sessionKey:_displaySessionKeys[indexPath.row]] autorelease];
            [delegate.navController pushViewController:sessionViewController animated:YES];
            */
        }        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark User alerts

- (NSString *)alertForProfileName:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile Name" message:@"Please enter a profile name" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    TSLModalAlertDelegate *delegate = [TSLModalAlertDelegate delegateWithAlert:alertView];
    NSUInteger result;
    if ((result = [delegate show])) {
        DLog(@"Alert for profile name returned with : %d", result);
        return [alertView textFieldAtIndex:0].text;
    }
    
    return nil;
}

- (void)dealloc {
    [_profilesTableView release];
    [_displayProfiles release];
    [_displaySessionKeys release];
    [_sessionDetailsButton release];
    [super dealloc];
}

@end
