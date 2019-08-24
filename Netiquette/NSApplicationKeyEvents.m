//
//  NSApplicationKeyEvents.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "NSApplicationKeyEvents.h"

@implementation NSApplicationKeyEvents

//to enable copy/paste etc even though we don't have an 'Edit' menu
// details: http://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
-(void) sendEvent:(NSEvent *)event
{
    //keydown?
    if([event type] == NSEventTypeKeyDown)
    {
        //command?
        if(([event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagCommand)
        {
            //+c
            // copy
            if(YES == [[event charactersIgnoringModifiers] isEqualToString:@"c"])
            {
                //copy
                if([self sendAction:@selector(copy:) to:nil from:self])
                {
                    return;
                }
            }
            
            //+a
            // select all
            else if([[event charactersIgnoringModifiers] isEqualToString:@"a"])
            {
                if ([self sendAction:@selector(selectAll:) to:nil from:self])
                {
                    return;
                }
            }
        }
    }
    
    //super
    [super sendEvent:event];
}

@end
