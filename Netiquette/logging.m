//
//  logging.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "consts.h"
#import "logging.h"

//log a msg
// default to syslog, and if an err msg, to disk
void logMsg(int level, NSString* msg)
{
    //log prefix
    NSMutableString* logPrefix = nil;
    
    //alloc/init
    // always start w/ name + pid
    logPrefix = [NSMutableString stringWithFormat:@"ReiKey(%d)", getpid()];
    
    //if its error, add error to prefix
    if(LOG_ERR == level)
    {
        //add
        [logPrefix appendString:@" ERROR"];
    }
    
    //debug mode logic
    #ifdef DEBUG
    
    //in debug mode promote debug msgs to LOG_NOTICE
    // OS X only shows LOG_NOTICE and above
    if(LOG_DEBUG == level)
    {
        //promote
        level = LOG_NOTICE;
    }
    
    #endif
    
    //dump to syslog?
    // function can be invoked just to log to file...
    if(0 != level)
    {
        //syslog
        syslog(level, "%s: %s", [logPrefix UTF8String], [msg UTF8String]);
    }

    return;
}

