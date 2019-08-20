//
//  event.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/6/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "consts.h"
#import "procInfo/procInfo.h"

#import <netdb.h>
#import <net/if.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern CFStringRef kNStatSrcKeyPID;
extern CFStringRef kNStatSrcKeyLocal;
extern CFStringRef kNStatSrcKeyRemote;
extern CFStringRef kNStatSrcKeyProvider;
extern CFStringRef kNStatSrcKeyTCPState;
extern CFStringRef kNStatSrcKeyInterface;

@interface Event : NSObject

/* PROPERTIES */

@property (nonatomic, retain) Process* process;

@property (nonatomic, retain) NSString* interface;

@property (nonatomic, retain) NSMutableDictionary* localAddress;
@property (nonatomic, retain) NSMutableDictionary* remoteAddress;

@property (nonatomic, retain) NSString* provider;
@property (nonatomic, retain) NSString* tcpState;

/* METHODS */

//init with event
// process raw event, adding process info, etc
-(id)init:(NSDictionary*)event;

//given a search string
// check if path, pid, ips, etc match?
-(BOOL)matches:(NSString*)search;

//convert to JSON
-(NSString*)toJSON;

@end

NS_ASSUME_NONNULL_END
