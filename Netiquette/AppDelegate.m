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
@synthesize zoomInMenuItem;
@synthesize zoomOutMenuItem;
@synthesize tableViewController;
@synthesize aboutWindowController;
@synthesize prefsWindowController;
@synthesize updateWindowController;

//(re)set toolbar style
-(void)awakeFromNib
{
    //bs's default toolbar style isn't good for us
    if(@available(macOS 11,*))
    {
        //set style
        self.window.toolbarStyle = NSWindowToolbarStyleExpanded;
    }
    
    //hide tab bar
    if (@available(macOS 10.12, *)) {
        [NSClassFromString(@"NSWindow") setAllowsAutomaticWindowTabbing:NO];
    }
    
    return;
}

//main app interface
// init UI and kick off monitoring
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //first listing?
    __block BOOL isFirstEnumeration = YES;
    
    //sorted events
    __block OrderedDictionary* sortedEvents = nil;
    
    //init monitor
    self.monitor = [[Monitor alloc] init];
    
    //automatically check for updates?
    // note: don't do this if running via LuLu
    if( (YES != [NSProcessInfo.processInfo.arguments containsObject:ARGS_LULU]) &&
        (YES != [NSUserDefaults.standardUserDefaults boolForKey:PREFS_NO_UPDATE]) )
    {
        //after a a few seconds
        // check for updates in background
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            
            //check
            [self check4Update:nil];

        });
    }
        
    //make main window active/front
    [self.window makeKeyAndOrderFront:self];
    
    //first time run (and not via LuLu)
    // show support/friends of objective-see window
    if( (YES != [NSProcessInfo.processInfo.arguments containsObject:ARGS_LULU]) &&
        (YES != [[NSUserDefaults standardUserDefaults] boolForKey:NOT_FIRST_TIME]) )
    {
        //set key
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NOT_FIRST_TIME];
        
        //front
        [self.friends makeKeyAndOrderFront:self];
        
        //make first responder
        // calling this without a timeout sometimes fails :/
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            
            //and make it first responder
            [self.friends makeFirstResponder:[self.friends.contentView viewWithTag:1]];
        });
    }
    
    //make app front
    [NSApp activateIgnoringOtherApps:YES];
    
    //start (connection) monitor
    // auto-refreshes ever 5 seconds
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //start (connection) monitor
        // auto-refreshes ever 5 seconds
        [self.monitor start:5 callback:^(NSMutableDictionary* events)
        {
            //sync
            @synchronized (self) {
                
                //keep memory in check
                @autoreleasepool {
                    
                    //column
                    __block NSUInteger column = 0;
                    
                    //direction
                    __block BOOL ascending = 0;
                    
                    //on main thread
                    // what to sort on?
                    dispatch_sync(dispatch_get_main_queue(),
                    ^{
                        //sort descriptors
                        NSArray<NSSortDescriptor *> *sortDescriptors = nil;
                        
                        //grab
                        sortDescriptors = self.tableViewController.outlineView.sortDescriptors;
                        
                        //no sort?
                        // default to first column and ascending
                        if(0 == sortDescriptors.count)
                        {
                            //default column
                            column = 0;
                            
                            //default direction
                            ascending = YES;
                        }
                        
                        //what was sorted (already)?
                        else
                        {
                            //column to sort on
                            column = [self.tableViewController columnIDToIndex:sortDescriptors.firstObject.key];
                            
                            //ascending?
                            ascending = sortDescriptors.firstObject.ascending;
                        }

                    });
                    
                    //combine
                    // and then sort events
                    sortedEvents = sortEvents(combineEvents(events), column, ascending);
        
                    //update table on main thread
                    dispatch_async(dispatch_get_main_queue(),
                    ^{
                        
                        //refresh table?
                        if( (YES == isFirstEnumeration) ||
                            (YES == [NSUserDefaults.standardUserDefaults boolForKey:PREFS_AUTO_REFRESH]) )
                        {
                            //update
                            isFirstEnumeration = NO;
                            
                            //update table
                            [self.tableViewController update:sortedEvents expand:YES reset:NO];
                        }
                        
                    });
                }
            }
        }];
        
    });
    
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
    if(UPDATE_NEW_VERSION == result)
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
        details = @"No new versions available";
            
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

//menu handler for 'view' menu
// actions include, refresh, zoom in/out, etc
-(IBAction)viewMenuHandler:(id)sender
{
    
    //tag
    NSInteger tag = 0;
    
    //init tag
    tag = ((NSButton*)sender).tag;
    
    //handle each
    switch (tag) {
            
        //expand
        case VIEW_EXPAND:
            [self.tableViewController expandAll];
            break;
        
        //collapse
        case VIEW_COLLAPSE:
            [self.tableViewController collapseAll];
            break;
        
        //zoom in
        case VIEW_ZOOM_IN:
            [self.tableViewController zoomIn];
            break;
        
        //zoom out
        case VIEW_ZOOM_OUT:
            [self.tableViewController zoomOut];
            break;
            
        default:
            break;
    }
    
    return;
}

//toggle menu item
-(void)toggleMenuItem:(NSMenuItem*)menuItem state:(NSControlStateValue)state
{
    //off?
    if(state == NSControlStateValueOff)
    {
        //disable
        [menuItem setTarget:nil];
        [menuItem setAction:NULL];
    }
        
    //on?
    else
    {
        //enable
        [menuItem setTarget:self];
        [menuItem setAction:@selector(viewMenuHandler:)];
    }
    
    return;
}

//menu handler: 'Preferences'
// alloc and show Preferences window
-(IBAction)showPreferences:(id)sender
{
    //alloc prefs window controller
    if(nil == self.prefsWindowController)
    {
        //alloc
        prefsWindowController = [[PrefsWindowController alloc] initWithWindowNibName:@"Preferences"];
    }
    
    //make active
    [self makeActive:self.prefsWindowController];
    
    return;
}

//menu handler: about
// alloc and show 'about' Window
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

//support handler
// open support (patreon) url
- (IBAction)supportUs:(id)sender
{
    //open URL
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:PATREON_URL]];
    
    //close window
    [self.friends close];
    
    return;
}

//don't support handler
//just close friends window
-(IBAction)closeSupportWindow:(id)sender
{
    //close window
    [self.friends close];
    
    return;
}

//make a window control/window front/active
-(void)makeActive:(NSWindowController*)windowController
{
    //make foreground
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    //center
    [windowController.window center];

    //show it
    [windowController showWindow:self];
    
    //make it key window
    [[windowController window] makeKeyAndOrderFront:self];
    
    //make window front
    [NSApp activateIgnoringOtherApps:YES];
    
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
