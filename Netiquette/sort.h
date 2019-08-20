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

/* FUNCTIONS */
 
//sort events
// create an ordered dictionary sorted by name
// pid 0: { event id 0: event, event id 1: event }
// pid 1: { event id 0: event, event id 1: event }
OrderedDictionary* sortEvents(NSMutableDictionary* events);


#endif /* sort_h */
