//
//  AppDelegate.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "sort.h"
#import "Event.h"
#import "AppDelegate.h"
#import "3rd-party/OrderedDictionary.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize friends;
@synthesize monitor;
@synthesize tableViewController;
@synthesize aboutWindowController;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //processed events
    __block OrderedDictionary* processedEvents = nil;
    
    //init monitor
    self.monitor = [[Monitor alloc] init];
    
    //center window
    [[self window] center];
    
    
    //first time run?
    // show thanks to friends window!
    // note: on close, invokes method to show main window
    if(YES != [[NSUserDefaults standardUserDefaults] boolForKey:NOT_FIRST_TIME])
    {
        //set key
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NOT_FIRST_TIME];
        
        //front
        [self.friends makeKeyAndOrderFront:self];
        
        //front
        [NSApp activateIgnoringOtherApps:YES];
        
        //make first responder
        // calling this without a timeout sometimes fails :/
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            
            //and make it first responder
            [self.friends makeFirstResponder:[self.friends.contentView viewWithTag:1]];
            
        });
        
        //close after 3 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            //close
            [self hideFriends:nil];
            
        });
    }
    
    //make main window active/front
    else
    {
        //make it key window
        [self.window makeKeyAndOrderFront:self];
        
        //make window front
        [NSApp activateIgnoringOtherApps:YES];
    }

    //start (connection) monitor
    // auto-refreshes ever 5 seconds
    [self.monitor start:5 callback:^(NSMutableDictionary* events)
    {
        //sync
        @synchronized (self) {
            
            //keep memory in check
            @autoreleasepool {
                
                //process events
                // combine into pid:connection(s)
                processedEvents = sortEvents(events);
                
                //update table on main thread
                dispatch_sync(dispatch_get_main_queue(),
                ^{
                  
                  //update table
                  [self.tableViewController update:processedEvents];
                    
                });
            }
            
            
        }
    }];
    
    return;
}

//automatically close when user closes last window
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

//app exit
// stop/cleanup monitor
-(void)applicationWillTerminate:(NSApplication *)application
{
    //stop/cleanup monitor
    if(nil != self.monitor)
    {
        //stop
        [self.monitor stop];
        
        //deinit
        [self.monitor deinit];
        
        //unset
        self.monitor = nil;
    }
    
    return;
}


//hide friends view
-(IBAction)hideFriends:(id)sender
{
    //once
    static dispatch_once_t onceToken;
    
    //close and launch main window
    dispatch_once (&onceToken, ^{
        
        //close
        [self.friends close];
        
    });
    
    return;
}

//menu handler: about
-(IBAction)about:(id)sender
{
    //alloc/init settings window
    if(nil == self.aboutWindowController)
    {
        //alloc/init
        aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    }
    
    //center window
    [[self.aboutWindowController window] center];
    
    //show it
    [self.aboutWindowController showWindow:self];
    
    return;
}

//menu handler: quit
-(IBAction)quit:(id)sender
{
    //exit
    [NSApp terminate:self];
    
    return;
}

@end
