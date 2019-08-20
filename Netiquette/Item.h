//
//  Item.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/20/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "procInfo/procInfo.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Item : NSObject

//process
@property(nonatomic, retain)Process* process;

//connections
@property(nonatomic, retain)NSMutableArray* connections;

/* METHODS */

//init
-(id)init:(Process*)process;

@end

NS_ASSUME_NONNULL_END
