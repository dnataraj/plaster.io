//
//  TSLModalAlertDelegate.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 7/24/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLModalAlertDelegate : NSObject <UIAlertViewDelegate>

@property (retain, nonatomic) UIAlertView *alertView;
@property NSUInteger index;

+ (id) delegateWithAlert: (UIAlertView *) anAlert;
- (int) show;

@end
