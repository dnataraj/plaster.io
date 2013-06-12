//
//  TSPlasterPeer.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 6/12/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPlasterPeer : NSObject

@property (readwrite, atomic, copy) NSString *peerID;
@property (readwrite, atomic, copy) NSString *peerAlias;

- (id)initWithPeer:(NSString *)aPeer;

@end
