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
NSString *const TSPlasterNotifySends = @"notify-sends";
NSString *const TSPlasterAllowCMDC = @"allow-cmdc";


// Constants for plaster transfers
NSString *const TSPlasterJSONKeyForPlasterType = @"plaster-type";
NSString *const TSPlasterJSONKeyForData = @"plaster-data";
NSString *const TSPlasterJSONKeyForSenderID = @"plaster-sender";

NSString *const TSPlasterTypeNotification = @"plaster-notification";
NSString *const TSPlasterTypeText = @"plaster-text";
NSString *const TSPlasterTypeImage = @"plaster-image";
NSString *const TSPlasterTypeFile = @"plaster-file";

NSString *const TSPlasterPacketText = @"plaster-packet-text";
NSString *const TSPlasterPacketImage = @"plaster-packet-image";
NSString *const TSPlasterPacketFile = @"plaster-packet-file";

const NSUInteger TSPlasterRedisKeyExpiry = 600;
