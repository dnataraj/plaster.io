//
//  TSActivityAlert.h
//  Partycipate-iOS
//
//  Created by Emiliano De Simone on 8/6/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLActivityAlert : NSObject

+ (void) presentWithText: (NSString *) alertText;
+ (void) dismiss;
+ (void) setTitle: (NSString *) aTitle;
+ (void) setMessage: (NSString *) aMessage;

@end
