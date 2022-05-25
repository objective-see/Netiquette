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
@synthesize processCache;

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
        
        //init cache
        processCache = [[NSCache alloc] init];
        
        //set cache limit
        self.processCache.countLimit = 2048;
        
        //create manager
        self.manager = NStatManagerCreate(kCFAllocatorDefault, self.queue,
        ^(NStatSourceRef source, void *unknown)
        {
           //set description block
           NStatSourceSetDescriptionBlock(source, ^(NSDictionary* description)
           {
               //event (conenction)
               Event* event = nil;
            
               //event (UUID)
               NSString* uuid = nil;
               
               //cached process
               Process* process = nil;
               
               //extract uuid
               uuid = description[kNStatSrcKeyUUID];
               if(0 != uuid.length)
               {
                   //try grab cached process
                   process = [self.processCache objectForKey:uuid];
               }
               
               //init event
               event = [[Event alloc] init:description process:process];
                   
               //ignore pid 0
               if(0 == event.process.pid)
               {
                   //igore
                   return;
               }
               
               //update process cache
               if(nil != uuid)
               {
                   //update
                   [self.processCache setObject:event.process forKey:uuid];
               }
            
               //sync
               @synchronized(self.events) {
                       
                    //update
                    self.events[[NSValue valueWithPointer:source]] = event;
                }
               
           });
       
           //set removed block
           NStatSourceSetRemovedBlock(source, ^()
           {
               //sync
               @synchronized(self) {
                    
                   //remove
                   self.events[[NSValue valueWithPointer:source]] = nil;
               }
              
           });
            
        });
        
        NStatManagerSetFlags(self.manager, 0);
    }
    
    return self;
}

//start (network) monitoring
-(void)start:(NSUInteger)refreshRate callback:(NetworkCallbackBlock)callback
{
    //watch UDP
    NStatManagerAddAllUDP(self.manager);
    
    //watch TCP
    NStatManagerAddAllTCP(self.manager);
    
    //query block
    // sync and call user-specified call back
    void (^queryCallback)(void) = ^(void) {

        //sync
        @synchronized(self.events)
        {
            //invoke user callback
            // pass copy to prevent access issues
            callback([self.events mutableCopy]);
        }
    };
    
    //query all to start
    NStatManagerQueryAllSourcesDescriptions(manager, queryCallback);
    
    //query all to start
    NStatManagerQueryAllSources(manager, queryCallback);
        
    //refresh?
    // call in timer/loop
    if(0 != refreshRate)
    {
        //set timer
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, refreshRate * NSEC_PER_SEC, 0);
        
        //set timer event handler
        dispatch_source_set_event_handler(self.timer, ^{
            
            //(re) query for connections
            NStatManagerQueryAllSourcesDescriptions(self.manager, queryCallback);
            
            //(re)  all to start
            NStatManagerQueryAllSources(self.manager, queryCallback);
            
        });
        
        //go!
        dispatch_resume(timer);
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
