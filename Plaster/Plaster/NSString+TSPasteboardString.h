//
//  NSString+TSPasteboardString.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/18/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TSPasteboardString)

@property (atomic, readwrite) NSNumber *peerCopy;

- (void)setPeerCopy:(NSNumber *)peerCopy;
- (NSNumber *)peerCopy;

@end
