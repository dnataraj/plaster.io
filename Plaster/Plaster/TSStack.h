//
//  TSStack.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSStack : NSObject

@property (readonly) id top;

- (void)push:(id)anObject;
- (id)pop;
- (BOOL)isEmpty;

@end
