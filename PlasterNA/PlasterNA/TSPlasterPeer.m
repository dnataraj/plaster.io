//
//  TSPlasterPeer.m
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/12/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import "TSPlasterPeer.h"

@implementation TSPlasterPeer

/*
    The peer identifiers passed in are of the form _clienID:friendly_host_name
    e.g : "FEA3BA39-DE83-40F0-BD2F-306E1D41391B_deepak's mac book"
    We split this up and store the tokens as peerID and peerAlias separately.
    This is a simple property class.
 
*/
- (id)initWithPeer:(NSString *)aPeer {
    self = [super init];
    if (self) {
        NSArray *tokens = [aPeer componentsSeparatedByString:@"_"];
        if ([tokens count] < 2) {
            DLog(@"Unable to initialize plaster peer.");
            return nil;
        }
        [self setPeerID:[tokens objectAtIndex:0]];
        [self setPeerAlias:[tokens objectAtIndex:1]];
    }
    
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"Plaster peer with id : %@ and alias : %@", [self peerID], [self peerAlias]];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TSPlasterPeer class]]) {
        return NO;
    }
    
    TSPlasterPeer *aPeer = (TSPlasterPeer *)object;
    if ([[self peerAlias] isEqualToString:[aPeer peerAlias]]) {
        return YES;
    }
    
    return NO;
}

- (void)dealloc {
    [_peerID release];
    [_peerAlias release];
    [super dealloc];
}

@end
