//
//  TSLNewSessionViewController.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/23/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSLNewSessionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView *sessionConfigurationTableView;
@property (retain, nonatomic) IBOutlet UILabel *sessionKeyLabel;

@property (retain, nonatomic) IBOutlet UITableViewCell *notificationCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowIncomingTextCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowIncomingImagesCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowOutgoingTextCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowOutgoingImagesCell;


@property (copy, readonly) NSString *sessionKey;


@end
