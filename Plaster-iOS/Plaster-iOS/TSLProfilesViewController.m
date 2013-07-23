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

@interface TSLProfilesViewController ()

@end

@implementation TSLProfilesViewController {
    TSLUserProfileDictator *_userProfileDicatator;
    NSMutableArray *_displayKeys;

    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        /*
        _startSessionBarButtonItem = [[UIBarButtonItem alloc] init];
        _startSessionBarButtonItem.title = @"New";
        _startSessionBarButtonItem.target = self;
        _startSessionBarButtonItem.action = @selector(startSession:);
        */
        _userProfileDicatator = [[TSLUserProfileDictator alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Profiles";
    //self.navigationItem.rightBarButtonItem = _startSessionBarButtonItem;
    _displayKeys = [[NSMutableArray alloc] init];
    [_displayKeys addObjectsFromArray:[[_userProfileDicatator plasterProfiles] allKeys]];
    DLog(@"Found profiles : %ld", (unsigned long)[_displayKeys count]);
    self.numberOfProfiles = [_displayKeys count];
    
    [_displayKeys addObjectsFromArray:@[@"New Plaster session", @"Join a session..."]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Action methods

- (void)startSession:(id)sender {
    NSLog(@"TSL: Session View Controller : Start session.");
}

#pragma mark UITableView data source methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO : Obtain stored profiles from user preferences. (allow user to delete these)
    return [_displayKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        NSLog(@"TSL: Session View Controller : Initializing cell at index path : %@", indexPath);
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
    }
    cell.textLabel.text = _displayKeys[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row >= self.numberOfProfiles) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark UITableView delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"Selected row at index path : %@", indexPath);
    TSLPlasterAppDelegate *delegate = (TSLPlasterAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (indexPath.row == ([_displayKeys count] - 2)) {
        DLog(@"Pushing new session view controller onto the nav...");
        TSLNewSessionViewController *newSessionViewController = [[TSLNewSessionViewController alloc] init];
        [delegate.navController pushViewController:newSessionViewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    //[_startSessionBarButtonItem release];
    [_sessionTableView release];
    [super dealloc];
}

@end
