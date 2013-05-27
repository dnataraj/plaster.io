//
//  TSStopWatch.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/26/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSStopWatch.h"

@interface TSStopWatch ()

@property (nonatomic, retain) NSDate* startDate;

@end

@implementation TSStopWatch

@synthesize name;
@synthesize runTime;
@synthesize startDate;

- (id) initWithName:(NSString*)_name {
	if ((self = [super init])) {
		self.name = _name;
		runTime = 0;
	}
	
	return self;
}

- (void) start {
	self.startDate = [NSDate date];
}

- (void) stop {
	runTime += -[startDate timeIntervalSinceNow];
}

- (void) statistics {
	NSLog(@"%@ finished in %f seconds.", name, runTime);
}



@end
