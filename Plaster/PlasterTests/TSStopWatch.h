//
//  TSStopWatch.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/26/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSStopWatch : NSObject {
	// Name to be used for logging
	NSString* name;
	
	// Total run time
	NSTimeInterval runTime;
	
	// The start date of the currently active run
	NSDate* startDate;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, readonly) NSTimeInterval runTime;

- (id) initWithName:(NSString*)name;

- (void) start;
- (void) stop;
- (void) statistics;

@end
