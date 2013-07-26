//
//  TSLModalAlertDelegate.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/24/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLModalAlertDelegate.h"

@implementation TSLModalAlertDelegate

- (id)initWithAlert: (UIAlertView *) anAlert {
    self = [super init];
    if (self) {
        self.alertView = anAlert;
    }
    return self;
}

-(void)alertView:(UIAlertView*)aView clickedButtonAtIndex:(NSInteger)anIndex {
    self.index = anIndex;
    self.alertView = nil;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (int) show {
    [self.alertView setDelegate:self];
    [self.alertView show];
    
    CFRunLoopRun();
    
    return self.index;
}

+ (id) delegateWithAlert: (UIAlertView *) anAlert {
    TSLModalAlertDelegate *mad = [[self alloc] initWithAlert:anAlert];
    return [mad autorelease];
}

- (void)dealloc
{
    [_alertView release];
    [super dealloc];
}

@end
