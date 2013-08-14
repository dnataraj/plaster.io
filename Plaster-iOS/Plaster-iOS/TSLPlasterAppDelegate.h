//
//  TSAppDelegate.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 6/11/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TSLPlasterController, TSLRedisController, TSViewController, TSLPlasterProfilesController;

@interface TSLPlasterAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic, retain) TSViewController *viewController;

@property (strong) TSLPlasterProfilesController *plasterProfileDictator;

@end
