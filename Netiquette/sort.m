//
//  sort.m
//  Netiquette
//
//  Created by Patrick Wardle on 8/19/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "sort.h"
#import <Foundation/Foundation.h>

//sort events
// create an ordered dictionary sorted by name
// pid 0: { event id 0: event, event id 1: event }
// pid 1: { event id 0: event, event id 1: event }
OrderedDictionary* sortEvents(NSMutableDictionary* events)
{
    //event
    Event* event = nil;
    
    //events (by pid)
    NSMutableDictionary* combinedEvents = nil;
    
    //sorted pids
    NSArray* sortedPids = nil;
    
    //processed events
    OrderedDictionary* processedEvents = nil;
    
    //pid
    NSNumber* processID = nil;
    
    //init dictionary for connections
    combinedEvents = [NSMutableDictionary dictionary];
    
    //init
    processedEvents = [[OrderedDictionary alloc] init];
    
    //create mapping
    // pid: { events }
    for(NSValue* key in events)
    {
        //extract event
        event = events[key];
        
        //extract pid
        processID = [NSNumber numberWithUnsignedInteger:event.process.pid];
        
        //first connection for process?
        // add, and allow list for connections
        if(nil == combinedEvents[processID])
        {
            //init list
            combinedEvents[processID] = [[OrderedDictionary alloc] init];
        }
        
        //add connection
        [combinedEvents[processID] setObject:event forKey:key];
    }
    
    //sort pids by process name
    sortedPids = [combinedEvents keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
    {
          //first event
          Event* firstEvent = [[((NSDictionary*)obj1) allValues] firstObject];
          
          //second event
          Event* secondEvent = [[((NSDictionary*)obj2) allValues] firstObject];
          
          //compare/return
          return [firstEvent.process.binary.name compare:secondEvent.process.binary.name options:NSCaseInsensitiveSearch];
    }];
    
    //sanity check
    if(0 == sortedPids.count)
    {
        //bail
        goto bail;
    }
    
    //add sorted events
    for(NSInteger i = 0; i<sortedPids.count-1; i++)
    {
        //add to ordered dictionary
        [processedEvents insertObject:combinedEvents[sortedPids[i]] forKey:sortedPids[i] atIndex:i];
    }
    
bail:
    return processedEvents;
}
