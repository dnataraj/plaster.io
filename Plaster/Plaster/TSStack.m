//
//  TSStack.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSStack.h"

@interface TSStack ()

@property (readwrite) id top;

@end

@implementation TSStack {
    NSMutableArray *_stack;
}

- (id)init {
    self = [super init];
    if (self) {
        _stack = [[NSMutableArray alloc] init];
        _top = nil;
    }
    
    return self;
}

- (void)push:(id)anObject {
    [_stack addObject:anObject];
    self.top = anObject;
}

- (id)pop {
    id popped = [_stack lastObject];
    if (popped) {
        [_stack removeLastObject];
        self.top = [_stack lastObject];
    }
    
    return popped;
}

- (BOOL)isEmpty {
    return ([_stack count] == 0);
}

@end
