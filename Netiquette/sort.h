//
//  sort.h
//  Netiquette
//
//  Created by Patrick Wardle on 8/19/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#ifndef sort_h
#define sort_h

#import "Event.h"
#import "3rd-party/OrderedDictionary.h"

//sort by
enum SortBy{SortByName, SortByProto, SortByInterface, SortByState, SortBytesUp, SortBytesDown};

/* FUNCTIONS */

//combine events
// create dictionary that combines events via their pid
// <pid>: { event id 0: event, event id 1: event }
NSMutableDictionary* combineEvents(NSMutableDictionary* events);
 
//sort events
// create an ordered dictionary based on column
OrderedDictionary* sortEvents(NSDictionary* events, NSUInteger column, BOOL ascending);

//sort events
// create an ordered dictionary sorted by traffic
OrderedDictionary* sortEventsByTraffic(NSDictionary* events, NSUInteger column, BOOL ascending);


#endif /* sort_h */
