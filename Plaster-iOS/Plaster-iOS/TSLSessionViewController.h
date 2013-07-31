//
//  TSLSessionViewController.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/30/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSLSessionViewController : UIViewController

@property (copy) NSString *sessionKey;
@property (retain) NSDictionary *profile;

@property (retain, nonatomic) IBOutlet UILabel *profileNameLabel;
@property (retain, nonatomic) IBOutlet UISwitch *sessionStartSwitch;
@property (retain, nonatomic) IBOutlet UITextView *sessionKeyTextView;


@property (atomic, getter = isOn) BOOL on;

- (id)initWithProfile:(NSDictionary *)aProfile sessionKey:(NSString *)key;
- (IBAction)toggleSessionState:(id)sender;

@end
