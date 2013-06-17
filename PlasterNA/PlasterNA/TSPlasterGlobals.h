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
#define PLASTER_SESSION_KEY_PREF @"plaster-session-key"
#define PLASTER_DEVICE_NAME_PREF @"plaster-device-name"
#define PLASTER_ALLOW_TEXT_TYPE_PREF @"plaster-allow-text"
#define PLASTER_ALLOW_IMAGE_TYPE_PREF @"plaster-allow-images"
#define PLASTER_ALLOW_FILE_TYPE_PREF @"plaster-allow-files"
#define PLASTER_NOTIFY_JOINS_PREF @"plaster-notify-joins"
#define PLASTER_NOTIFY_DEPARTURES_PREF @"plaster-notify-departures"
#define PLASTER_NOTIFY_PLASTERS_PREF @"plaster-notify-plasters"

// Keys used in the JSON packet
#define PLASTER_TYPE_JSON_KEY @"plaster-type"
#define PLASTER_DATA_JSON_KEY @"plaster-data"
#define PLASTER_SENDER_JSON_KEY @"plaster-sender"
#define PLASTER_TEXT_TYPE_JSON_VALUE @"plaster-text"
#define PLASTER_IMAGE_TYPE_JSON_VALUE @"plaster-image"
#define PLASTER_FILE_TYPE_JSON_VALUE @"plaster-file"

// Keys used for decoded data
#define PLASTER_PACKET_TEXT @"plaster-packet-text"
#define PLASTER_PACKET_IMAGE @"plaster-packet-image"

#endif
