//
//  Monitor.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/6/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "Event.h"
#import "Monitor.h"

@implementation Monitor

@synthesize queue;
@synthesize timer;
@synthesize events;
@synthesize manager;

-(id)init
{
    //super
    self = [super init];
    if(self != nil)
    {
        //init queue
        self.queue = dispatch_queue_create("netiquette", NULL);
        
        //init timer
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
        
        //init dictionary for events
        self.events = [NSMutableDictionary dictionary];
        
        //create manager
        self.manager = NStatManagerCreate(kCFAllocatorDefault, self.queue,
        ^(NStatSourceRef source, void *unknown)
        {
           //set description block
           NStatSourceSetDescriptionBlock(source, ^(CFDictionaryRef description)
           {
               //set block
               [self callbackDescription:source description:(__bridge NSDictionary *)(description)];
           });
           
           //set removed block
           NStatSourceSetRemovedBlock(source, ^()
           {
               //set block
               [self callbackRemoved:source];
           });
            
        });
    }
    
    return self;
}

//callback for new event
-(void)callbackDescription:(NStatSourceRef)source description:(NSDictionary*)description
{
    //sync
    @synchronized(self.events) {
        
        //init event
        Event* event = [[Event alloc] init:description];
        
        //update
        // source will be unique per connection
        self.events[[NSValue valueWithPointer:source]] = event;
    }
}


//callback for removed event
// remove source, and call block that was passed in
-(void)callbackRemoved:(NStatSourceRef)source
{
    //sync
    @synchronized(self) {
        
        //remove
        self.events[[NSValue valueWithPointer:source]] = nil;
    }
    
    //since we're auto-refreshing
    // don't need to callback directly...

    return;
}

//start (network) monitoring
-(void)start:(NSUInteger)refreshRate callback:(NetworkCallbackBlock)callback
{
    //watch UDP
    NStatManagerAddAllUDP(self.manager);
    
    //watch TCP
    NStatManagerAddAllTCP(self.manager);
    
    //refresh?
    if(0 != refreshRate)
    {
        //set timer
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, refreshRate * NSEC_PER_SEC, 0);
        
        //set timer event handler
        dispatch_source_set_event_handler(self.timer, ^{
            
            //query for connections
            NStatManagerQueryAllSourcesDescriptions(self.manager, ^(void)
            {
                //sync
                // then invoke user callback
                @synchronized (self.events)
                {
                    //invoke user callback
                    // pass copy to prevent access issues
                    callback([self.events mutableCopy]);
                }
                                                        
            });
        });
        
        //go!
        dispatch_resume(timer);
    }
    
    else
    {
        //query for connections
        NStatManagerQueryAllSourcesDescriptions(self.manager, ^()
        {
            //sync
            // then invoke user callback
            @synchronized(self.events)
            {
                //invoke user callback
                callback(self.events);
            }
        });
    }
    
    return;
}

//stop
-(void)stop
{
    //suspender timer
    dispatch_suspend(self.timer);
    
    return;
}

//deinit
// stop q
// destroy manager
-(void)deinit
{
    //stop queueu
    if(nil != self.queue)
    {
        //stop
        dispatch_suspend(self.queue);
        
        //unset
        self.queue = nil;
    }
    
    //destroy monitor
    if(nil != self.manager)
    {
        //destroy
        NStatManagerDestroy(self.manager);
        
        //unset
        self.manager = nil;
    }
    
    return;
}

@end
