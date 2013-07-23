//
//  TSLNewSessionViewController.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLNewSessionViewController.h"
#import "TSLClientIdentifier.h"

@interface TSLNewSessionViewController ()

@property (copy, readwrite) NSString *sessionKey;

@end

@implementation TSLNewSessionViewController {
    NSArray *_rowsInSection;
    NSArray *_sectionHeaders;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        DLog(@"Initializing rows and section headers...");
        _rowsInSection = [@[@1, @2, @2] retain];
        _sectionHeaders = [@[@"Notifications", @"Incoming Plasters", @"Outgoing Plasters"] retain];
    }
    return self;
}

- (id)init {
    return [self initWithNibName:@"TSLNewSessionViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.sessionKey = [TSLClientIdentifier createUUID];
    self.sessionKeyLabel.text = self.sessionKey;
}


#pragma mark UITableView data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DLog(@"Requesting number of rows in section : %d", section);
    // Section 0 : Notification
    // Section 1 : Incoming plaster configuration
    // Section 2 : Outgoing plaster configuration
    return [_rowsInSection[section] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case 0:
            DLog(@"Requesting notification cell..");
            cell = [self.notificationCell retain];
            break;
        case 1:
            if (indexPath.row == 0) {
                cell = self.allowIncomingTextCell;
            } else if (indexPath.row == 1) {
                cell = self.allowIncomingImagesCell;
            }
            break;
        case 2:
            if (indexPath.row == 0) {
                cell = self.allowOutgoingTextCell;
            } else if (indexPath.row == 1) {
                cell = self.allowOutgoingImagesCell;
            }
            break;
        default:
            cell = [self.notificationCell retain];
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DLog(@"Requesting title for header in section : %d", section);
    return _sectionHeaders[section];
}


#pragma mark UITableView delegate methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_sessionConfigurationTableView release];
    [_sessionKeyLabel release];
    [_notificationCell release];
    [_allowIncomingTextCell release];
    [_allowIncomingImagesCell release];
    [_allowOutgoingTextCell release];
    [_allowOutgoingImagesCell release];
    
    [_rowsInSection release];
    [_sectionHeaders release];
    [super dealloc];
}
@end
