//
//  TSLSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLProfilesViewController.h"
#import "TSLUserProfileDictator.h"
#import "TSLPlasterAppDelegate.h"
#import "TSLNewSessionViewController.h"
#import "TSLModalAlertDelegate.h"
#import "TSLPlasterGlobals.h"
#import "TSLSessionViewController.h"

@interface TSLProfilesViewController () {
    TSLUserProfileDictator *_userProfileDicatator;
    NSMutableArray *_displayProfiles;
    NSMutableArray *_displaySessionKeys;
}

@end

@implementation TSLProfilesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _userProfileDicatator = [[TSLUserProfileDictator alloc] init];
        _displayProfiles = nil;
        _displaySessionKeys = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Profiles";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resetDisplayKeys];    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing != self.editing) {
        [super setEditing:editing animated:animated];
        [self.sessionTableView setEditing:editing animated:animated];
        
        NSMutableArray *indices = [[NSMutableArray alloc] init];
        for (int i=0; i < self.numberOfProfiles; i++) {
            [indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        NSArray *lastIndex = @[[NSIndexPath indexPathForRow:self.numberOfProfiles inSection:0], [NSIndexPath indexPathForRow:(self.numberOfProfiles + 1) inSection:0]];
        if (editing == YES) {
            for (int i = 0; i < self.numberOfProfiles; i++) {
                UITableViewCell *cell = [self.sessionTableView cellForRowAtIndexPath:indices[i]];
                DLog(@"Setting accessory type for cell in Edit mode...");
                [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            [self.sessionTableView deleteRowsAtIndexPaths:lastIndex withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            for (int i = 0; i < self.numberOfProfiles; i++) {
                UITableViewCell *cell = [self.sessionTableView cellForRowAtIndexPath:indices[i]];
                [cell setEditingAccessoryType:UITableViewCellAccessoryNone];
            }
            
            [self.sessionTableView insertRowsAtIndexPaths:lastIndex withRowAnimation:UITableViewRowAnimationLeft];
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
    
    NSDictionary *profiles = [_userProfileDicatator plasterProfiles];
    for (NSString *key in [profiles keyEnumerator]) {
        NSDictionary *profileConfiguration = [profiles objectForKey:key];
        DLog(@"Found profile : %@", profileConfiguration);
        
        [_displayProfiles addObject:[profileConfiguration objectForKey:TSPlasterProfileName]];
        [_displaySessionKeys addObject:key];
    }
    
    DLog(@"Found profiles : %@", _displayProfiles);
    self.numberOfProfiles = [_displayProfiles count];
    DLog(@"Found session keys : %@", _displaySessionKeys);
    
    [_displayProfiles addObjectsFromArray:@[@"New Plaster session", @"Join a session..."]];
    [self.sessionTableView reloadData];
}

#pragma mark Action methods

- (void)startSession:(id)sender {
    NSLog(@"TSL: Session View Controller : Start session.");
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        NSLog(@"TSL: Session View Controller : Initializing cell at index path : %@", indexPath);
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
    }
    //DLog(@"Returning cell for index row : %d with label : %@", indexPath.row, _displayProfiles[indexPath.row]);
    cell.textLabel.text = _displayProfiles[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row >= self.numberOfProfiles) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark UITableView delegate methods

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"Attempting to delete row with index path : %@", indexPath);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_displayProfiles removeObjectAtIndex:indexPath.row];
        [_userProfileDicatator removeProfileWithKey:_displaySessionKeys[indexPath.row]];
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
    } else {
        NSDictionary *profile = [[_userProfileDicatator plasterProfiles] objectForKey:_displaySessionKeys[indexPath.row]];
        DLog(@"Obtained stored profile : %@", profile);
        // For re-configuring existing sessions in edit mode
        if (self.editing) {
            DLog(@"Pushing new session view controller onto the nav for editing existing profiles...");
            TSLNewSessionViewController *newSessionViewController = [[[TSLNewSessionViewController alloc] initWithProfile:profile
                                                                                                               sessionKey:_displaySessionKeys[indexPath.row]
                                                                                                                  editing:self.editing] autorelease];
            [delegate.navController pushViewController:newSessionViewController animated:YES];
        } else {
            // User taps a session to start it
            DLog(@"Starting session with key : %@", _displaySessionKeys[indexPath.row]);
            TSLSessionViewController *sessionViewController = [[[TSLSessionViewController alloc] initWithProfile:profile
                                                                                                      sessionKey:_displaySessionKeys[indexPath.row]] autorelease];
            [delegate.navController pushViewController:sessionViewController animated:YES];
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
    [_sessionTableView release];
    [_displayProfiles release];
    [_displaySessionKeys release];
    [super dealloc];
}

@end
