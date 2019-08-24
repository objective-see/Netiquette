//
//  utilities.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/14/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#ifndef utilities_h
#define utilities_h

#import "3rd-party/OrderedDictionary.h"

#import <arpa/inet.h>
#import <Foundation/Foundation.h>

/* FUNCTIONS */

//disable std err
void disableSTDERR(void);

//init crash reporting
void initCrashReporting(void);

//get app's version
// extracted from Info.plist
NSString* getAppVersion(void);

//transform app state
OSStatus transformApp(ProcessApplicationTransformState newState);

//check if (full) dark mode
BOOL isDarkMode(void);

//loads a framework
// note: assumes it is in 'Framework' dir
NSBundle* loadFramework(NSString* name);

//convert IP addr to (ns)string
// from: https://stackoverflow.com/a/29147085/3854841
NSString* convertIPAddr(unsigned char* ipAddr, __uint8_t socketFamily);

//format results
// convert to JSON
NSMutableString* formatResults(OrderedDictionary* connections, BOOL skipApple);

//prettify JSON
NSString* prettifyJSON(NSString* output);

//make a window modal
void makeModal(NSWindowController* windowController);

#endif /* utilities_h */
