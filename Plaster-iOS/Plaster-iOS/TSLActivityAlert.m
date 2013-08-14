//
//  TSActivityAlert.m
//  Partycipate-iOS
//
//  Created by Emiliano De Simone on 8/6/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLActivityAlert.h"

static UIAlertView *alertView = nil;
static UIActivityIndicatorView *activity = nil;


@implementation TSLActivityAlert

+ (void) presentWithText: (NSString *) alertText
{
    if (alertView)
    {
        alertView.title = alertText;
        [alertView show];
    }
    else
    {
        alertView = [[UIAlertView alloc] initWithTitle:alertText message:@"\n\n\n" delegate:nil cancelButtonTitle:nil otherButtonTitles: nil];
        [alertView show];
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        // activity.color = [UIColor redColor]; // you can set colors
        activity.center = CGPointMake(CGRectGetMidX(alertView.bounds), CGRectGetMidY(alertView.bounds));
        [activity startAnimating];
        [alertView addSubview: activity];
    }
}

+ (void) setTitle: (NSString *) aTitle
{
    alertView.title = aTitle;
}

+ (void) setMessage: (NSString *) aMessage;
{
    NSString *message = aMessage;
    while ([message componentsSeparatedByString:@"\n"].count < 7)
        message = [message stringByAppendingString:@"\n"];
    alertView.message = message;
}

+ (void) dismiss
{
    if (alertView)
    {
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
        
        [activity removeFromSuperview];
        activity = nil;
        alertView = nil;
    }
}

@end
