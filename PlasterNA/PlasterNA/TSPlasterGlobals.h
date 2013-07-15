//
//  TSPlasterGlobals.h
//  Plaster
//
//  Created by Deepak Natarajan on 5/15/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#ifndef Plaster_TSPlasterGlobals_h
#define Plaster_TSPlasterGlobals_h

#define WOOKIE_IP "176.9.2.188"
#define LOCAL_IP "127.0.0.1"
#define REDIS_IP "176.9.2.188"
#define REDIS_PORT 6379

#define DEFAULT_PUBLISHER TSRedisController

extern NSString *const TSCurrentSessionKey;

// Keys for various user preferences.
extern NSString *const TSPlasterDeviceName;
extern NSString *const TSPlasterProfiles;
extern NSString *const TSPlasterSessionKey;
extern NSString *const TSPlasterProfileName;
extern NSString *const TSPlasterAllowText;
extern NSString *const TSPlasterAllowImages;
extern NSString *const TSPlasterAllowFiles;
extern NSString *const TSPlasterOutAllowText;
extern NSString *const TSPlasterOutAllowImages;
extern NSString *const TSPlasterOutAllowFiles;
extern NSString *const TSPlasterNotifyJoins;
extern NSString *const TSPlasterNotifyDepartures;
extern NSString *const TSPlasterNotifyPlasters;
extern NSString *const TSPlasterMode;
extern NSString *const TSPlasterModePasteboard;
extern NSString *const TSPlasterModeFile;
extern NSString *const TSPlasterFolderPath;

// Keys used in the JSON packet
extern NSString *const TSPlasterJSONKeyForPlasterType;
extern NSString *const TSPlasterJSONKeyForData;
extern NSString *const TSPlasterJSONKeyForSenderID;

extern NSString *const TSPlasterTypeNotification;
extern NSString *const TSPlasterTypeText;
extern NSString *const TSPlasterTypeImage;
extern NSString *const TSPlasterTypeFile;

// Keys used for decoded data
extern NSString *const TSPlasterPacketText;
extern NSString *const TSPlasterPacketImage;
extern NSString *const TSPlasterPacketFile;

#endif
