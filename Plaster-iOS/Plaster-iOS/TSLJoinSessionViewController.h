//
//  TSLJoinSessionViewController.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/1/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSLJoinSessionViewController : UIViewController

@property (retain, nonatomic) IBOutlet UILabel *joinProfileNameLabel;
@property (retain, nonatomic) IBOutlet UITextView *sessionKeyEntryTextView;

@property (copy, nonatomic) NSString *profileName;

- (id)initWithProfileName:(NSString *)profileName;
- (IBAction)joinSession:(id)sender;
- (IBAction)joinWithDefaults:(id)sender;

@end
