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

-(IBAction)showPreferences:(id)sender;

@end

