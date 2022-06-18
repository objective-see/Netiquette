//
//  consts.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/14/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#ifndef consts_h
#define consts_h

#define PROCESS_PID @"pid"
#define PROCESS_PATH @"path"

#define INTERFACE @"interface"
#define PROTOCOL @"protocol"

#define LOCAL_PORT @"localPort"
#define LOCAL_ADDRESS @"localAddress"

#define REMOTE_PORT @"remotePort"
#define REMOTE_HOST @"remoteHostName"
#define REMOTE_ADDRESS @"remoteAddress"

#define CONNECTION_STATE @"state"

#define BYTES_UP @"bytesUp"
#define BYTES_DOWN @"bytesDown"

#define KEY_PORT @"port"
#define KEY_FAMILY @"family"
#define KEY_ADDRRESS @"address"
#define KEY_HOST_NAME @"hostName"

//product name
// ...for version check
#define PRODUCT_NAME @"Netiquette"

//sentry crash reporting URL
#define SENTRY_DSN @"https://1735fa7903114215993cb18c96fe268c@sentry.io/1535612"

//product url
#define PRODUCT_URL @"https://objective-see.org/products/netiquette.html"

//patreon url
#define PATREON_URL @"https://www.patreon.com/bePatron?c=701171"

//path to CUPS
#define CUPS @"/usr/sbin/cupsd"

//product version url
#define PRODUCT_VERSIONS_URL @"https://objective-see.org/products.json"

//update error
#define UPDATE_ERROR -1

//update no new version
#define UPDATE_NOTHING_NEW 0

//update new version
#define UPDATE_NEW_VERSION 1

#define PREFS_HIDE_APPLE          @"hideApple"
#define PREFS_AUTO_REFRESH        @"autoRefresh"
#define PREFS_RESOLVE_NAMES       @"resolveNames"
#define PREFS_HIDE_LOCAL          @"hideLocalHost"
#define PREFS_NO_UPDATE           @"noUpdateCheck"

//executed via LuLu
#define ARGS_LULU @"-lulu"

//view menu
#define VIEW_EXPAND                1
#define VIEW_COLLAPSE              2
#define VIEW_ZOOM_IN               3
#define VIEW_ZOOM_OUT              4

#endif /* consts_h */
