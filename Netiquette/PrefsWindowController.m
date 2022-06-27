//
//  file: PrefsWindowController.h
//  project: Netiquette
//  description: preferences window controller (header)
//
//  created by Patrick Wardle
//  copyright (c) 2020 Objective-See. All rights reserved.
//

#import "consts.h"
#import "Update.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "PrefsWindowController.h"
#import "UpdateWindowController.h"

/* GLOBALS */

@implementation PrefsWindowController

@synthesize toolbar;
@synthesize generalView;
@synthesize updateView;
@synthesize updateWindowController;

//pref button IDS
#define BUTTON_AUTO_REFRESH 1
#define BUTTON_RESOLVE_NAMES 2
#define BUTTON_HIDE_APPLE 3
#define BUTTON_HIDE_LOCAL 4
#define BUTTON_NO_UPDATE 5

//init 'general' view
// add it, and make it selected
-(void)awakeFromNib
{
    //(un)set button handler
    [self toolbarButtonHandler:nil];
    
    //set general prefs as default
    [self.toolbar setSelectedItemIdentifier:TOOLBAR_GENERAL_ID];
    
    return;
}

//toolbar view handler
// toggle view based on user selection
-(IBAction)toolbarButtonHandler:(id)sender
{
    //view
    NSView* view = nil;
    
    //when we've prev added a view
    // remove the prev view cuz adding a new one
    if(nil != sender)
    {
        //remove
        [[[self.window.contentView subviews] lastObject] removeFromSuperview];
    }
    
    //assign view
    switch(((NSToolbarItem*)sender).tag)
    {
        //modes
        case TOOLBAR_GENERAL:
        {
            //set view
            view = self.generalView;
            
            //auto refresh
            ((NSButton*)[view viewWithTag:BUTTON_AUTO_REFRESH]).state = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_AUTO_REFRESH];
            
            //resolve names
            ((NSButton*)[view viewWithTag:BUTTON_RESOLVE_NAMES]).state = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_RESOLVE_NAMES];
            
            //hide apple
            ((NSButton*)[view viewWithTag:BUTTON_HIDE_APPLE]).state = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_APPLE];
            
            //hide local
            ((NSButton*)[view viewWithTag:BUTTON_HIDE_LOCAL]).state = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_LOCAL];
            
            break;
        }
            
        //update
        case TOOLBAR_UPDATE:
        {
            //set view
            view = self.updateView;
    
            //set 'update' button state
            ((NSButton*)[view viewWithTag:BUTTON_NO_UPDATE]).state = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_NO_UPDATE];
            
            //set button as first responder
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                
                //make first responder
                [self.window makeFirstResponder:self.updateButton];
            });
            
            break;
        }
            
        default:
            
            //bail
            goto bail;
    }
    
    //set frame rect
    view.frame = CGRectMake(0, 75, self.window.contentView.frame.size.width, self.window.contentView.frame.size.height-75);
    
    //add to window
    [self.window.contentView addSubview:view];
    
bail:
    
    return;
}


//invoked when user toggles button
// update preferences for that button
-(IBAction)togglePreference:(id)sender
{
    //preferences
    NSMutableDictionary* updatedPreferences = nil;
    
    //button state
    BOOL state = NO;
    
    //init
    updatedPreferences = [NSMutableDictionary dictionary];
    
    //get button state
    state = ((NSButton*)sender).state;
    
    //set appropriate preference
    switch(((NSButton*)sender).tag)
    {
        //auto-refresh
        case BUTTON_AUTO_REFRESH:
        {
            //set
            [NSUserDefaults.standardUserDefaults setBool:state forKey:PREFS_AUTO_REFRESH];
            
            break;
        }
        
        //resolve names
        case BUTTON_RESOLVE_NAMES:
        {
            //set
            [NSUserDefaults.standardUserDefaults setBool:state forKey:PREFS_RESOLVE_NAMES];
            
            break;
        }
        
        //hide apple procs
        case BUTTON_HIDE_APPLE:
        {
            //set
            [NSUserDefaults.standardUserDefaults setBool:state forKey:PREFS_HIDE_APPLE];
            break;
        }
            
        //hide localhost connections
        case BUTTON_HIDE_LOCAL:
        {
            //set
            [NSUserDefaults.standardUserDefaults setBool:state forKey:PREFS_HIDE_LOCAL];
            break;
        }
    
        //no update mode
        case BUTTON_NO_UPDATE:
        {
            //set
            [NSUserDefaults.standardUserDefaults setBool:state forKey:PREFS_NO_UPDATE];
            break;
        }
            
        default:
            break;
    }
    
    //sync
    [NSUserDefaults.standardUserDefaults synchronize];
    
    return;
}

//'check for update' button handler
-(IBAction)check4Update:(id)sender
{
    //update obj
    Update* update = nil;
    
    //disable button
    self.updateButton.enabled = NO;
    
    //reset
    self.updateLabel.stringValue = @"";
    
    //show/start spinner
    [self.updateIndicator startAnimation:self];
    
    //init update obj
    update = [[Update alloc] init];
    
    //check for update
    // 'updateResponse newVersion:' method will be called when check is done
    [update checkForUpdate:^(NSUInteger result, NSString* newVersion) {
        
        //process response
        [self updateResponse:result newVersion:newVersion];
        
    }];
    
    return;
}

//process update response
// error, no update, update/new version
-(void)updateResponse:(NSInteger)result newVersion:(NSString*)newVersion
{
    //re-enable button
    self.updateButton.enabled = YES;
    
    //stop/hide spinner
    [self.updateIndicator stopAnimation:self];
    
    switch(result)
    {
        //error
        case -1:
            
            //set label
            self.updateLabel.stringValue = @"error: update check failed";
            
            break;
            
        //no updates
        case 0:
            
            //set label
            self.updateLabel.stringValue = [NSString stringWithFormat:@"Installed version (%@),\r\nis the latest.", getAppVersion()];
            
            break;
         
            
        //new version
        case 1:
            
            //alloc update window
            updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
            
            //configure
            [self.updateWindowController configure:[NSString stringWithFormat:@"a new version (%@) is available!", newVersion] buttonTitle:@"Update"];
            
            //center window
            [[self.updateWindowController window] center];
            
            //show it
            [self.updateWindowController showWindow:self];
            
            //invoke function in background that will make window modal
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                //make modal
                makeModal(self.updateWindowController);
                
            });
            
            break;
    }
    
    return;
}

//on window close
// refresh UI (outline view)
-(void)windowWillClose:(NSNotification *)notification
{
    //refresh
    [((AppDelegate*)NSApplication.sharedApplication.delegate).tableViewController refresh];
    
    return;
}


@end
