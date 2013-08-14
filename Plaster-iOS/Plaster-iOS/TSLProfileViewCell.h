//
//  TSLProfileViewCell.h
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/5/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSLProfileViewCell : UITableViewCell

@property (retain, nonatomic) UIActivityIndicatorView *plasterStartingIndicator;

@property (copy, nonatomic) NSDictionary *profile;

@property (nonatomic, getter = isRunning) BOOL running;
@property (nonatomic, readonly) NSArray *peers;

@end
