//
//  TSPlasterFile.h
//  PlasterNA
//
//  Created by Deepak Natarajan on 7/16/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *PLASTER_FILE_UTI;

@interface TSPlasterFile : NSObject <NSPasteboardReading, NSPasteboardWriting>

@property (copy) NSURL *fileURL;

- (id)initWithURL:(NSURL *)anURL;


@end
