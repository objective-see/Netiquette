//
//  AppDelegate.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "sort.h"
#import "Event.h"
#import "Update.h"
#import "utilities.h"
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
@synthesize updateWindowController;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //processed events
    __block OrderedDictionary* processedEvents = nil;
    
    //init monitor
    self.monitor = [[Monitor alloc] init];
    
    //center window
    [[self window] center];
    
    //after a a few seconds
    // check for updates in background
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
       //check
        [self check4Update:nil];
       
    });

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

//call into Update obj
// check to see if there an update?
-(IBAction)check4Update:(id)sender
{
    //update obj
    Update* update = nil;
    
    //init update obj
    update = [[Update alloc] init];
    
    //check for update
    // ->'updateResponse newVersion:' method will be called when check is done
    [update checkForUpdate:^(NSUInteger result, NSString* newVersion) {
        
        //show update window?
        if( (nil != sender) ||
            (UPDATE_NEW_VERSION == result) )
        {
            //process response
            [self updateResponse:result newVersion:newVersion];
        }
    }];
    
    return;
}

//process update response
// error, no update, update/new version
-(void)updateResponse:(NSInteger)result newVersion:(NSString*)newVersion
{
    //details
    NSString* details = nil;
    
    //action
    NSString* action = nil;
    
    //new version?
    // configure ui, and add 'update' button
    if(UPDATE_NEW_VERSION== result)
    {
        //set details
        details = [NSString stringWithFormat:@"a new version (%@) is available!", newVersion];
        
        //set action
        action = @"Update";
        
        //alloc update window
        updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
        
        //configure
        [self.updateWindowController configure:details buttonTitle:action];
        
        //center window
        [[self.updateWindowController window] center];
        
        //show it
        [self.updateWindowController showWindow:self];
        
        //invoke function in background that will make window modal
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //make modal
            makeModal(self.updateWindowController);
            
        });
    }
    
    //no new version
    // configure ui, and add 'close' button
    else
    {
        //set details
        details = @"no new versions available";
            
        //set action
        action = @"Close";
        
        //alloc update window
        updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
        
        //configure
        [self.updateWindowController configure:details buttonTitle:action];
        
        //center window
        [[self.updateWindowController window] center];
        
        //show it
        [self.updateWindowController showWindow:self];
        
        //invoke function in background that will make window modal
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //make modal
            makeModal(self.updateWindowController);
            
        });
    }
    
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
