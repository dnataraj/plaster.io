//
//  TSAppDelegate.m
//  Plaster
//
//  Created by Deepak Natarajan on 5/14/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSAppDelegate.h"
#import "TSStack.h"
#import "TSPasteboardPacket.h"
#import "TSRedisController.h"
#import "TSEventDispatcher.h"

@implementation TSAppDelegate {
    NSStatusItem *_plasterStatusItem;
    TSStack *_pbStack;
    NSPasteboard *_generalPasteBoard;
    NSArray *_readables;
    
    void (^extractLatestCopy)(void);
    NSInteger _changeCount;
    //dispatch_queue_t _queue;
    //dispatch_source_t _timer;
    
    TSRedisController *_redisController;
    TSEventDispatcher *_dispatcher;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _pbStack = [[TSStack alloc] init];
    _generalPasteBoard = [NSPasteboard generalPasteboard];
    _changeCount = [_generalPasteBoard changeCount];
    _readables = [NSArray arrayWithObject:[NSString class]];
    _dispatcher = [[TSEventDispatcher alloc] init];
    
    NSLog(@"Initializing block...");
    extractLatestCopy = ^(void) {
        NSInteger newChangeCount = [_generalPasteBoard changeCount];
        if (_changeCount == newChangeCount) {
            return;
        }
        _changeCount = [_generalPasteBoard changeCount];
        NSArray *pbContents = [_generalPasteBoard readObjectsForClasses:_readables options:nil];
        NSLog(@"Found in pasteboard : [%@]" , [pbContents objectAtIndex:0]);
        
    };
    
    //_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // Initialize redis controller
    _redisController = [[TSRedisController alloc] initWithDispatcher:_dispatcher];
    NSLog(@"Ready to roll...");
}

- (void)awakeFromNib {
    _plasterStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_plasterStatusItem setTitle:@"P"];
    [_plasterStatusItem setHighlightMode:YES];
    [_plasterStatusItem setMenu:[self plasterMenu]];
    
    [self.stopMenuItem setEnabled:NO];
}

/*
- (dispatch_source_t) createTimerWithInterval:(uint64_t)interval andLeeway:(uint64_t)leeway {
    NSLog(@"Creating a dispatch timer...");
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, extractLatestCopy);
        dispatch_resume(timer);
    }
    
    return timer;
}

- (void)stopTimer:(dispatch_source_t)aTimer {
    dispatch_source_cancel(aTimer);
}
 */

- (IBAction)start:(id)sender {
    NSLog(@"Starting pasteboard monitoring...");
    /*
    _timer = [self createTimerWithInterval:(0.1 * NSEC_PER_SEC) andLeeway:(0.003 * NSEC_PER_SEC)];
    if (!_timer) {
        NSLog(@"Unable to create timer!");
    }
     */
    [_dispatcher dispatchTask:@"pbpoller" WithPeriod:(15 * NSEC_PER_MSEC) andHandler:extractLatestCopy];
    [self.startMenuItem setEnabled:NO];
    [self.stopMenuItem setEnabled:YES];
}

- (IBAction)stop:(id)sender {
    NSLog(@"Stopping timer and cleaning up...");
    //[self stopTimer:_timer];
    [_dispatcher stopTask:@"pbpoller"];
    [self.startMenuItem setEnabled:YES];
    [self.stopMenuItem setEnabled:NO];
}

@end
