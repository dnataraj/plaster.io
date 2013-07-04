//
//  TSRedisController.h
//  Plaster
//
//  Created by Deepak Natarajan on 6/26/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSPlasterGlobals.h"

NSString *const TSCurrentSessionKey = @"plaster-current-session";

// Constants for profile configuration
NSString *const TSPlasterDeviceName = @"plaster-device-name";
NSString *const TSPlasterProfiles = @"plaster-profiles";
NSString *const TSPlasterSessionKey = @"plaster-session-key";
NSString *const TSPlasterProfileName = @"profile-name";
NSString *const TSPlasterAllowText = @"allow-text";
NSString *const TSPlasterAllowImages = @"allow-images";
NSString *const TSPlasterAllowFiles = @"allow-files";
NSString *const TSPlasterOutAllowText = @"allow-out-text";
NSString *const TSPlasterOutAllowImages = @"allow-out-images";
NSString *const TSPlasterOutAllowFiles = @"allow-out-files";
NSString *const TSPlasterNotifyJoins = @"notify-joins";
NSString *const TSPlasterNotifyDepartures = @"notify-departures";
NSString *const TSPlasterNotifyPlasters = @"notify-plasters";
NSString *const TSPlasterMode = @"mode";
NSString *const TSPlasterModePasteboard = @"PASTEBOARD";
NSString *const TSPlasterModeFile = @"FILE";
NSString *const TSPlasterFolderPath = @"folder-path";

