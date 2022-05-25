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

extern NSConstantString* kNStatSrcKeyPID;
extern NSConstantString* kNStatSrcKeyUUID;
extern NSConstantString* kNStatSrcKeyLocal;
extern NSConstantString* kNStatSrcKeyRemote;
extern NSConstantString* kNStatSrcKeyTxBytes;
extern NSConstantString* kNStatSrcKeyRxBytes;
extern NSConstantString* kNStatSrcKeyProvider;
extern NSConstantString* kNStatSrcKeyTCPState;
extern NSConstantString* kNStatSrcKeyInterface;

@interface Event : NSObject

/* PROPERTIES */

@property (nonatomic, retain) Process* process;

@property (nonatomic, retain) NSString* interface;

@property (nonatomic, retain) NSMutableDictionary* localAddress;
@property (nonatomic, retain) NSMutableDictionary* remoteAddress;

@property (nonatomic, retain) NSString* provider;
@property (nonatomic, retain) NSString* tcpState;

@property unsigned long bytesUp;
@property unsigned long bytesDown;

/* METHODS */

//init with event
// process raw event, adding process info, etc
-(id)init:(NSDictionary*)event process:(Process*)process;

//given a search string
// check if path, pid, ips, etc match?
-(BOOL)matches:(NSString*)search;

//convert to JSON
-(NSString*)toJSON;

@end

NS_ASSUME_NONNULL_END
