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
#define PLASTER_TYPE_JSON_KEY @"plaster-type"
#define PLASTER_DATA_JSON_KEY @"plaster-data"
#define PLASTER_SENDER_JSON_KEY @"plaster-sender"
#define PLASTER_FILENAME_JSON_KEY @"plaster-file-name"

// Standard values used in the JSON packet
#define PLASTER_TEXT_TYPE_JSON_VALUE @"plaster-text"
#define PLASTER_IMAGE_TYPE_JSON_VALUE @"plaster-image"
#define PLASTER_FILE_TYPE_JSON_VALUE @"plaster-file"

// Keys used for decoded data
#define PLASTER_PACKET_TEXT @"plaster-packet-text"
#define PLASTER_PACKET_IMAGE @"plaster-packet-image"
#define PLASTER_PACKET_FILE @"plaster-packet-file"

#endif
