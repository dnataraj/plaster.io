//
//  TSAppDelegate.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 6/11/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TSViewController;

@interface TSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) TSViewController *viewController;

@end
