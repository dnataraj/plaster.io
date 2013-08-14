//
//  TSLProfileViewCell.m
//  Plaster-iOS
//
//  Created by Deepak Natarajan on 8/5/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSLProfileViewCell.h"

@interface TSLProfileViewCell ()
@end

@implementation TSLProfileViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        DLog(@"Initializing activity indicator view for cell...");
        _plasterStartingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _plasterStartingIndicator.hidesWhenStopped = YES;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        DLog(@"Starting activity indicator animation...");
        self.accessoryView = self.plasterStartingIndicator;
        [self.plasterStartingIndicator startAnimating];
    }
}

- (void)dealloc {
    [_plasterStartingIndicator release];
    [_profile release];
    [_peers release];
    [super dealloc];
}

@end
