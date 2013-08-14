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
#import "TSLPlasterProfilesController.h"
#import "TSLPlasterProfile.h"
#import "TSLActivityAlert.h"

@interface TSLPlasterAppDelegate () {
    TSLPlasterProfilesController *_plasterProfilesController;
    TSLProfilesViewController *_profilesViewController;
}

@end

@implementation TSLPlasterAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    [TSLActivityAlert presentWithText: [NSString stringWithFormat:@"Starting..."]];
    
    _plasterProfilesController = [[TSLPlasterProfilesController alloc] init];
    
    // Clean up previous session if needed, but only if there is no current session
    NSString *lastSessionKey = [_plasterProfilesController currentSessionKey];
    TSLRedisController *provider = [[[TSLRedisController alloc] initWithIPAddress:@"176.9.2.188" port:6379] autorelease];
    TSLPlasterController *plasterController = [[[TSLPlasterController alloc] initWithPasteboard:[UIPasteboard generalPasteboard]
                                                                                       provider:provider] autorelease];
    [plasterController setSessionKey:lastSessionKey];
    if (lastSessionKey) {
        // Clean up any stale sessions in case there was a dirty exit previously
        NSArray *staleSessions = @[lastSessionKey];
        [plasterController setAlias:[[UIDevice currentDevice] name]];
        DLog(@"Verifying disconnect from sessions : %@", staleSessions);
        NSDictionary *options = @{@"controller" : plasterController, @"sessions" : staleSessions};
        [self performSelector:@selector(initializePlaster:) withObject:options afterDelay:0];
    }
    
    // Override point for customization after application launch.
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[TSViewController alloc] initWithNibName:@"TSViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[TSViewController alloc] initWithNibName:@"TSViewController_iPad" bundle:nil] autorelease];
    }
    */
    
    // The navigation controller will handle plaster session views.
    _profilesViewController = [[TSLProfilesViewController alloc] initWithNibName:@"TSLProfilesViewController"
                                                                                            bundle:nil];
    self.navController = [[UINavigationController alloc] initWithRootViewController:_profilesViewController];

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
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Plaster" message:notification.alertBody delegate:nil
                                                  cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        
        TSLModalAlertDelegate *delegate = [TSLModalAlertDelegate delegateWithAlert:alertView];
        NSUInteger result;
        if ((result = [delegate show])) {
            DLog(@"Alert for plaster returned with : %d", result);
        }        
    }
    
    [_profilesViewController.profilesTableView reloadData];

    return;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DLog(@"WHOA! DIDBECOMEACTIVE!");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DLog(@"Application will terminate. Stopping any running plaster sessions.");
}

- (void)initializePlaster:(NSDictionary *)options {
    [(TSLPlasterController *)options[@"controller"] disconnectFromSessions:@[@"sessions"]];
    [TSLActivityAlert dismiss];
}

- (void)dealloc {
    [_window release];
    [_viewController release];
    [_profilesViewController release];
    [_plasterProfileDictator release];
    [super dealloc];
}


@end
