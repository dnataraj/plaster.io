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
@property (retain, nonatomic) IBOutlet UILabel *profileNameLabel;


@property (retain, nonatomic) IBOutlet UITableViewCell *notificationCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowIncomingTextCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowIncomingImagesCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowOutgoingTextCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *allowOutgoingImagesCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *profileNameCell;

@property (retain, nonatomic) IBOutlet UISwitch *notificationsSwitch;
@property (retain, nonatomic) IBOutlet UISwitch *allowIncomingTextSwitch;
@property (retain, nonatomic) IBOutlet UISwitch *allowIncomingImagesSwitch;
@property (retain, nonatomic) IBOutlet UISwitch *allowOutgoingTextSwitch;
@property (retain, nonatomic) IBOutlet UISwitch *allowOutgoingImagesSwitch;

@property BOOL shouldNotify, allowIncomingText, allowIncomingImages, allowOutgoingText, allowOutgoingImages;
@property (copy, nonatomic) NSString *profileName;

@property (copy, readonly) NSString *sessionKey;
@property BOOL editProfile;

- (id)initWithProfileName:(NSString *)profileName;
- (id)initWithProfile:(NSDictionary *)profile sessionKey:(NSString *)key editing:(BOOL)editing;

- (IBAction)switchNotifications:(id)sender;
- (IBAction)switchAllowIncomingText:(id)sender;
- (IBAction)switchAllowIncomingImages:(id)sender;
- (IBAction)switchAllowOutgoingText:(id)sender;
- (IBAction)switchAllowOutgoingImages:(id)sender;


@end
