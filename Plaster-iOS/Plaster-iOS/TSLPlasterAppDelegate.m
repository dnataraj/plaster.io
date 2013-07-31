//
//  TSAppDelegate.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 6/11/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLPlasterAppDelegate.h"

#import "TSViewController.h"
#import "TSLProfilesViewController.h"
#import "TSLPreferencesViewController.h"
#import "TSLSessionViewController.h"
#import "TSLPlasterController.h"
#import "TSLRedisController.h"
#import "TSLModalAlertDelegate.h"

@implementation TSLPlasterAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    self.redisController = [[[TSLRedisController alloc] initWithIPAddress:@"176.9.2.188" port:6379] autorelease];
    self.plasterController = [[TSLPlasterController alloc] initWithPasteboard:[UIPasteboard generalPasteboard] provider:_redisController];
    
    // Override point for customization after application launch.
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[TSViewController alloc] initWithNibName:@"TSViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[TSViewController alloc] initWithNibName:@"TSViewController_iPad" bundle:nil] autorelease];
    }
    */
     
    // The navigation controller will handle plaster session views.
    UIViewController *profilesViewController = [[[TSLProfilesViewController alloc] initWithNibName:@"TSLProfilesViewController"
                                                                                            bundle:nil] autorelease];
    self.navController = [[UINavigationController alloc] initWithRootViewController:profilesViewController];

    UIViewController *preferencesViewController = [[[TSLPreferencesViewController alloc] initWithNibName:@"TSLPreferencesViewController"
                                                                                                  bundle:nil] autorelease];
    
    // The plaster iOS tab bar (bottom)
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.viewControllers = @[self.navController, preferencesViewController];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    DLog(@"Recieved local notification : %@", notification.alertBody);
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Plaster" message:notification.alertBody delegate:nil
                                              cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    TSLModalAlertDelegate *delegate = [TSLModalAlertDelegate delegateWithAlert:alertView];
    NSUInteger result;
    if ((result = [delegate show])) {
        DLog(@"Alert for plaster returned with : %d", result);
    }

    return;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    /*
    UIViewController *visibleVC = self.navController.visibleViewController;
    if (![visibleVC isKindOfClass:[TSLSessionViewController class]]) {
        DLog(@"User was not starting a plaster session.");
        return;
    }
    
    __block TSLSessionViewController *__sessionVC = (TSLSessionViewController *)visibleVC;
    if ([__sessionVC isOn]) {
        [self.plasterController setSessionKey:[__sessionVC sessionKey]];
        [self.plasterController setSessionProfile:[__sessionVC profile]];
        [self.plasterController setAlias:[[UIDevice currentDevice] name]];
        
        __block TSLPlasterController *__plasterController = self.plasterController;
        
        __block UIBackgroundTaskIdentifier plasterBgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            DLog(@"Plaster background monitor was stiatched. Cleaning up...");
            [__plasterController stop];
            __plasterController = nil;
            __sessionVC.on = NO;
            DLog(@"Stopping background task...");
            [application endBackgroundTask:plasterBgTask];
            plasterBgTask = UIBackgroundTaskInvalid;
        }];
        
        if (plasterBgTask == UIBackgroundTaskInvalid) {
            DLog(@"iOS Kernel refuses to create plaster background monitor. Stiatched.");
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.plasterController start];            
        });
        
    } else {
        DLog(@"Plaster session, not on. No background work.");
    }
    */
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)dealloc {
    [_window release];
    [_viewController release];
    [super dealloc];
}


@end
