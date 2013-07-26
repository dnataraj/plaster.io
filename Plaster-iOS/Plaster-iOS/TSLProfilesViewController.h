//
//  TSLSessionViewController.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSLProfilesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView *sessionTableView;

@property (atomic) NSUInteger numberOfProfiles;

- (void)startSession:(id)sender;

@end
