//
//  AppDelegate.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "Monitor.h"
#import "TableViewController.h"
#import "AboutWindowController.h"
#import "PrefsWindowController.h"
#import "UpdateWindowController.h"

#import <Cocoa/Cocoa.h>

//not first run
#define NOT_FIRST_TIME @"notFirstTime"


@interface AppDelegate : NSObject <NSApplicationDelegate>

/* PROPERTIES */

//friends of objective-see window
@property (weak) IBOutlet NSWindow *friends;

//menu items
@property (weak) IBOutlet NSMenuItem *zoomInMenuItem;
@property (weak) IBOutlet NSMenuItem *zoomOutMenuItem;

//update window controller
@property(nonatomic, retain)UpdateWindowController* updateWindowController;

//about window controller
@property(nonatomic, retain)AboutWindowController* aboutWindowController;

//preferences window controller
@property(nonatomic, retain)PrefsWindowController* prefsWindowController;

//connection monitor
@property (nonatomic, retain)Monitor* monitor;

//table view controller
@property (weak) IBOutlet TableViewController *tableViewController;

/* METHODS */

//show prefs
-(IBAction)showPreferences:(id)sender;

//menu handler
-(IBAction)viewMenuHandler:(id)sender;

//toggle menu item
-(void)toggleMenuItem:(NSMenuItem*)menuItem state:(NSControlStateValue)state;

@end

