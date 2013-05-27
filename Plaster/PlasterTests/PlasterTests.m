//
//  PlasterTests.m
//  PlasterTests
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "PlasterTests.h"
#import "TSPlasterController.h"
#import "TSRedisController.h"
#import "TSDataStoreProvider.h"
#import "TSMessagingProvider.h"

#import "TSStopWatch.h"

@implementation PlasterTests {
    //id <TSMessagingProvider, TSDataStoreProvider> testRedisController;
}

- (void)setUp {
    [super setUp];
    //testRedisController = [[TSRedisController alloc] init];
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    //[(TSRedisController *) testRedisController terminate];
    //testRedisController = nil;
    [super tearDown];
}

- (void)testSetStringValueforKey {
    id <TSMessagingProvider, TSDataStoreProvider> testRedisController = [[TSRedisController alloc] initWithIPAddress:@"127.0.0.1" andPort:6379];
    
    NSString *testMethod = NSStringFromSelector(@selector(setStringValue:withKey:andSignal:));
    TSStopWatch *watch = [[TSStopWatch alloc] initWithName:testMethod];
    [watch start];
    
    // Test the set
    [testRedisController setStringValue:testMethod forKey:testMethod];
    // Verify with get
    NSString *value = [testRedisController stringValueForKey:testMethod];

    [watch stop];
    STAssertTrue([testMethod isEqualToString:value], @"ERROR : SET VALUE %@ GOT VALUE %@ FOR KEY %@", testMethod, value, testMethod);
    [watch statistics];
    
    [(TSRedisController *) testRedisController terminate];
    testRedisController = nil;
}

- (void)testSetNXStringValueforKey {
    id <TSMessagingProvider, TSDataStoreProvider> testRedisController = [[TSRedisController alloc] init];
    
    NSString *testMethod = NSStringFromSelector(@selector(setNXStringValue:forKey:));
    TSStopWatch *watch = [[TSStopWatch alloc] initWithName:testMethod];
    [watch start];
    BOOL exists = [testRedisController setNXStringValue:testMethod forKey:testMethod];
    STAssertTrue(exists, @"ERROR : SET should return 1");
    exists = [testRedisController setNXStringValue:testMethod forKey:testMethod];
    STAssertFalse(exists, @"ERROR : SET should return 0");
    [watch stop];
    [watch statistics];
    
    [(TSRedisController *) testRedisController terminate];
    testRedisController = nil; 
}

- (void)testIncrementKey {
    id <TSMessagingProvider, TSDataStoreProvider> testRedisController = [[TSRedisController alloc] init];
    
    NSString *testMethod = NSStringFromSelector(@selector(incrementKey:));
    TSStopWatch *watch = [[TSStopWatch alloc] initWithName:testMethod];
    [watch start];
    [testRedisController setStringValue:@"100" forKey:testMethod];
    NSUInteger inc = [testRedisController incrementKey:testMethod];
    [watch stop];
    STAssertTrue(inc == 101, @"ERROR : Expected 101, got %d", inc);
    [watch statistics];

    [(TSRedisController *) testRedisController terminate];
    testRedisController = nil;
}


@end
