//
//  NSString+TSBase64.h
//  TSBase64
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TSBase64)

- (NSString *)base64String;
- (NSData *)dataFromBase64;

@end
