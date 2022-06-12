//
//  Monitor.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/6/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//wish there was a `NetworkStatistics.h`
// mahalo J. Levin:
//   https://twitter.com/Morpheus______
//   http://newosxbook.com/src.jl?tree=listings&file=netbottom.c

typedef void *NStatSourceRef;
typedef NSObject* NStatManagerRef;

NStatManagerRef NStatManagerCreate (const struct __CFAllocator *, dispatch_queue_t, void (^)(void *, void *));

void NStatSourceSetDescriptionBlock (NStatSourceRef arg,  void (^)(NSDictionary*));
void NStatSourceSetRemovedBlock (NStatSourceRef arg,  void (^)(void));

void NStatManagerAddAllTCP(NStatManagerRef manager);
void NStatManagerAddAllUDP(NStatManagerRef manager);

void NStatManagerQueryAllSources(NStatManagerRef manager, void (^)(void) );
void NStatManagerQueryAllSourcesDescriptions(NStatManagerRef manager, void (^)(void) );

void NStatManagerDestroy(NStatManagerRef manager);
int NStatManagerSetFlags(NStatManagerRef, int Flags);

//block for library
typedef void (^NetworkCallbackBlock)(NSMutableDictionary* _Nonnull);

@interface Monitor : NSObject

/* PROPERTIES */

@property (nullable) dispatch_queue_t queue;
@property (nullable) dispatch_source_t timer;
@property (nullable) NStatManagerRef manager;
@property (nonatomic, retain)NSCache* processCache;
@property (nonatomic, retain)NSMutableDictionary* events;


/* METHODS */

//start (network) monitoring
-(void)start:(NSUInteger)refreshRate callback:(NetworkCallbackBlock)callback;

//stop
-(void)stop;

//deinit
-(void)deinit;

@end

NS_ASSUME_NONNULL_END
