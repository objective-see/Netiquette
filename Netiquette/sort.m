//
//  sort.m
//  Netiquette
//
//  Created by Patrick Wardle on 8/19/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "sort.h"
#import <Foundation/Foundation.h>

//combine events
// create dictionary that combines events via their pid
// <pid>: { event id 0: event, event id 1: event }
NSMutableDictionary* combineEvents(NSMutableDictionary* events)
{
    //event
    Event* event = nil;
    
    //events (by pid)
    NSMutableDictionary* combinedEvents = nil;
    
    //pid
    NSNumber* processID = nil;
    
    //init dictionary for connections
    combinedEvents = [NSMutableDictionary dictionary];
    
    //create mapping
    // pid: { events }
    for(NSValue* key in events)
    {
        //extract event
        event = events[key];
        
        //extract pid
        processID = [NSNumber numberWithUnsignedInteger:event.process.pid];
        
        //first connection for process?
        // add with alloc'd list for connections
        if(nil == combinedEvents[processID])
        {
            //init list
            combinedEvents[processID] = [[OrderedDictionary alloc] init];
        }
        
        //add connection
        [combinedEvents[processID] setObject:event forKey:key];
    }
    
    return combinedEvents;
}

//sort events
OrderedDictionary* sortEvents(NSDictionary* events, NSUInteger column, BOOL ascending)
{
    //sorted pids
    NSArray* sortedPids = nil;
    
    //processed events
    OrderedDictionary* sortedEvents = nil;
    
    //last two columns (bytes up/down) are special
    if( (column == 4) || (column == 5) )
    {
        //sort traffic
        sortedEvents = sortEventsByTraffic(events, column, ascending);
        
        //done
        goto bail;
    }
    
    //init
    sortedEvents = [[OrderedDictionary alloc] init];
    
    //sort pids by process name
    sortedPids = [events keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
    {
        //first event
        Event* firstEvent = nil;
        
        //second event
        Event* secondEvent = nil;
        
        //ascending
        // init first and second
        if(YES == ascending)
        {
            //init first
            firstEvent = [[((NSDictionary*)obj1) allValues] firstObject];
            
            //init second
            secondEvent = [[((NSDictionary*)obj2) allValues] firstObject];
        }
        
        //descending
        // init first and second (flipped)
        else
        {
            //init first
            firstEvent = [[((NSDictionary*)obj2) allValues] firstObject];
            
            //init second
            secondEvent = [[((NSDictionary*)obj1) allValues] firstObject];
        }
    
        //sort by what?
        switch (column) {
                
            //process name
            case 0:
                
                //compare/return name
                return [firstEvent.process.binary.name compare:secondEvent.process.binary.name options:NSCaseInsensitiveSearch];
                break;
                
            /*
            //protocol
            case 1:
                
                //compare/return protocol (provider)
                return [firstEvent.provider compare:secondEvent.provider options:NSCaseInsensitiveSearch];
                break;
                
            //interface
            case 2:
                
                //compare/return interface
                return [firstEvent.interface compare:secondEvent.interface options:NSCaseInsensitiveSearch];
                break;
                
            //state
            case 3:
                
                //compare/return state
                return [firstEvent.tcpState compare:secondEvent.tcpState options:NSCaseInsensitiveSearch];
                break;
            */
            
            default:
                return NSOrderedAscending;
        }
        
    }];
    
    //sanity check
    if(0 == sortedPids.count)
    {
        //bail
        goto bail;
    }
    
    //add sorted events
    for(NSInteger i = 0; i<sortedPids.count; i++)
    {
        //add to ordered dictionary
        [sortedEvents insertObject:events[sortedPids[i]] forKey:sortedPids[i] atIndex:i];
    }
    
bail:
    
    return sortedEvents;
}

//sort events
// create an ordered dictionary sorted by traffic
OrderedDictionary* sortEventsByTraffic(NSDictionary* events, NSUInteger column, BOOL ascending)
{
    //sorted pids
    NSArray* sortedPids = nil;
    
    //processed events
    OrderedDictionary* sortedEvents = nil;
    
    //init
    sortedEvents = [[OrderedDictionary alloc] init];
    
    //sort pids by process name
    sortedPids = [events keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
    {
        //total(s)
        unsigned long total1 = 0;
        unsigned long total2 = 0;
        
        //compute total one
        for(Event* event in [((NSDictionary*)obj1) allValues])
        {
            if(SortBytesUp == column)
            {
                //sum
                total1 += event.bytesUp;
            }
            else if(SortBytesDown == column)
            {
                //sum
                total1 += event.bytesDown;
            }
        }
        
        //compute total two
        for(Event* event in [((NSDictionary*)obj2) allValues])
        {
            if(SortBytesUp == column)
            {
                //sum
                total2 += event.bytesUp;
            }
            else if(SortBytesDown == column)
            {
                //sum
                total2 += event.bytesDown;
            }
        }
        
        //ascending
        if(YES == ascending)
        {
            if (total1 < total2) return NSOrderedAscending;
            else return NSOrderedDescending;
        }
        //descending
        else
        {
            if (total1 < total2) return NSOrderedDescending;
            else return NSOrderedAscending;
        }
    }];
    
    //sanity check
    if(0 == sortedPids.count)
    {
        //bail
        goto bail;
    }
    
    //add sorted events
    for(NSInteger i = 0; i<sortedPids.count; i++)
    {
        //add to ordered dictionary
        [sortedEvents insertObject:events[sortedPids[i]] forKey:sortedPids[i] atIndex:i];
    }
    
bail:
    
    return sortedEvents;
}
