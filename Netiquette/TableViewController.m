//
//  TableViewController.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/20/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

//id (tag) for detailed text in category table
#define TABLE_ROW_NAME_TAG 100

//id (tag) for detailed text in category table
#define TABLE_ROW_SUB_TEXT_TAG 101

#define BUTTON_SAVE         1
#define BUTTON_PREFS        2
#define BUTTON_LOGO         3
#define BUTTON_EXPAND       4
#define BUTTON_COLLAPSE     5

#define MAX_ZOOM_SCALE      25
#define DEFAULT_FONT_SIZE   16
#define DEFAULT_ROW_HEIGHT  45

#import "sort.h"
#import "Event.h"
#import "consts.h"
#import "CustomRow.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "TableViewController.h"

@implementation TableViewController

@synthesize items;
@synthesize zoomScale;
@synthesize filterString;
@synthesize collapsedItems;
@synthesize processedItems;

//perform some init's
-(void)awakeFromNib
{
    //once
    static dispatch_once_t once = 0;
    
    dispatch_once (&once, ^{
        
        //only generate events end events
        self.filterBox.sendsWholeSearchString = YES;
        
        //alloc
        self.collapsedItems = [NSMutableDictionary dictionary];
        
        //pre-req for color of overlay
        self.overlay.wantsLayer = YES;
        
        //round overlay's corners
        self.overlay.layer.cornerRadius = 20.0;
        
        //mask overlay
        self.overlay.layer.masksToBounds = YES;
        
        //set overlay's view color to gray
        self.overlay.layer.backgroundColor = NSColor.lightGrayColor.CGColor;
        
        //set (default) scanning msg
        self.activityMessage.stringValue = @"Enumerating Network Connections...";
        
        //show overlay
        self.overlay.hidden = NO;
        
        //show activity indicator
        self.activityIndicator.hidden = NO;
        
        //start activity indicator
        [self.activityIndicator startAnimation:nil];
        
        //init sort descriptor for name column
        self.outlineView.tableColumns[0].sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:[self.outlineView.tableColumns[0] identifier] ascending:NO];
        
        //init sort descriptor for bytes up column
        self.outlineView.tableColumns[4].sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:[self.outlineView.tableColumns[4] identifier] ascending:YES];
        
        //init sort descriptor for bytes down column
        self.outlineView.tableColumns[5].sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:[self.outlineView.tableColumns[5] identifier] ascending:YES];
        
        //table resizing settings
        [self.outlineView sizeLastColumnToFit];
        
        //default zoom
        self.zoomScale = 100.00f;
        
    });
    
    return;
}

//update outline view
-(void)update:(OrderedDictionary*)updatedItems expand:(BOOL)expand reset:(BOOL)reset
{
    //selected row
    __block NSInteger selectedRow = -1;
    
    //item's (new?) row
    __block NSInteger itemRow = -1;
    
    //currently selected item
    __block id selectedItem = nil;
    
    //once
    static dispatch_once_t once;
    
    //sync
    // filter & reload
    @synchronized (self)
    {

    //update
    self.items = updatedItems;
        
    //get currently selected row
    // default to first row if this fails
    selectedRow = self.outlineView.selectedRow;
    if(-1 == selectedRow)
    {
        //default
        selectedRow = 0;
    }
        
    //grab selected item
    selectedItem = [self.outlineView itemAtRow:selectedRow];
    
    //filter
    self.processedItems = [self filter];
        
    //first time
    // remove/update
    dispatch_once(&once, ^{
        
        //hide activity indicator
        self.activityIndicator.hidden = YES;
        
        //nothing found?
        // update overlay, then fade out
        if(0 == self.processedItems.count)
        {
            //ignore apple?
            // set message about 3rd-party
            if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_APPLE])
            {
                //set msg
                self.activityMessage.stringValue = @"No (3rd-party) Network Connections Detected";
            }
            
            //full scan
            // set message about all
            else
            {
                //set msg
                self.activityMessage.stringValue = @"No Network Connections Detected";
            }
            
            //fade-out overlay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                //begin grouping
                [NSAnimationContext beginGrouping];
                
                //set duration
                [[NSAnimationContext currentContext] setDuration:2.0];
                
                //fade out
                [[self.overlay animator] removeFromSuperview];
                
                //end grouping
                [NSAnimationContext endGrouping];
                
            });
        }
        
        //hide overlay
        else
        {
            //hide
            self.overlay.hidden = YES;
        }
    });
    
    //begin updates
    [self.outlineView beginUpdates];
    
    //full reload
    [self.outlineView reloadData];
    
    //auto expand
    [self.outlineView expandItem:nil expandChildren:expand];

    //end updates
    [self.outlineView endUpdates];
    
    //get selected item's (new) row
    itemRow = [self.outlineView rowForItem:selectedItem];
    if(-1 != itemRow)
    {
        //set
        selectedRow = itemRow;
    }
        
    //prev selected now beyond bounds?
    // just default to select last row...
    selectedRow = MIN(selectedRow, (self.outlineView.numberOfRows-1));
        
    //reset?
    if(YES == reset)
    {
        //top
        selectedRow = 0;
    }
    
    //(re)select
    dispatch_async(dispatch_get_main_queue(),
    ^{
        //select
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        
        //reset?
        // scroll to selected row
        if(YES == reset)
        {
            //scroll
            [self.outlineView scrollRowToVisible:selectedRow];
        }
    });
        
    } //sync
    
bail:
        
    return;
}

//detect when user collapses a row
-(void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    //item
    OrderedDictionary* item = nil;
    
    //pid
    NSNumber* pid = nil;
    
    //grab item
    item = notification.userInfo[@"NSObject"];
    if(YES != [item isKindOfClass:[OrderedDictionary class]])
    {
        //bail
        goto bail;
    }
    
    //grab pid
    pid = [NSNumber numberWithInt:((Event*)[[item allValues] firstObject]).process.pid];
    
    //save
    self.collapsedItems[pid] = item;
    
bail:
    
    return;
}

//determine if item should be collapsed
// basically, if user has collapsed it, leave it collapsed (on reload)
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    //flag
    // default to 'YES'
    BOOL shouldExpand = YES;
    
    //pid
    NSNumber* pid = nil;
    
    //grab pid
    pid = [NSNumber numberWithInt:((Event*)[[item allValues] firstObject]).process.pid];
    
    //item was (user) collapsed?
    if(nil != self.collapsedItems[pid])
    {
        //'new' item
        // means auto-reloaded, so leave collapsed
        if(self.collapsedItems[pid] != item)
        {
            //set flag
            shouldExpand = NO;
            
            //insert
            self.collapsedItems[pid] = item;
        }
        //same item
        // means user is attempting to (re)expand
        else
        {
            //remove
            [self.collapsedItems removeObjectForKey:pid];
        }
    }

    return shouldExpand;
}

//number of the children
-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    //# of children
    // root: all
    // non-root, just items in item
    return (nil == item) ? self.processedItems.count : [item count];
}

//processes are expandable
// these items are built from items of type array
-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (YES == [item isKindOfClass:[OrderedDictionary class]]);
}

//return child
-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    //child
    id child = nil;
    
    //key
    id key = nil;
    
    //root item?
    // 'child' it just top level item
    if(nil == item)
    {
        //key
        key = [self.processedItems keyAtIndex:index];
        
        //child
        child = [self.processedItems objectForKey:key];
        
    }
    //otherwise
    // child is event at index
    else
    {
        //key
        key = [item keyAtIndex:index];
        
        //child
        child = [item objectForKey:key];
    }
    
    return child;
}

//return custom row for view
// allows highlighting, etc...
-(NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    //row view
    CustomRow* rowView = nil;
    
    //row ID
    static NSString* const kRowIdentifier = @"RowView";
    
    //try grab existing row view
    rowView = [self.outlineView makeViewWithIdentifier:kRowIdentifier owner:self];
    
    //make new if needed
    if(nil == rowView)
    {
        //create new
        // ->size doesn't matter
        rowView = [[CustomRow alloc] initWithFrame:NSZeroRect];
        
        //set row ID
        rowView.identifier = kRowIdentifier;
    }
    
    return rowView;
}

//table delegate method
// return new cell for row
-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    //view
    NSView* cell = nil;
    
    //first event
    Event* event = nil;
    
    //flag
    BOOL isProcessCell = NO;
    
    //set process cell flag
    isProcessCell = [item isKindOfClass:[OrderedDictionary class]];
    
    //set event
    if(YES == isProcessCell)
    {
        //grab firt event
        event = [[item allValues] firstObject];
    }
    else
    {
        //typecast
        event = (Event*)item;
    }
    
    //first column
    // process or connection cell
    if(tableColumn == self.outlineView.tableColumns[0])
    {
        //init process cell
        if(YES == isProcessCell)
        {
            //create/configure
            cell = [self createProcessCell:event.process];
        }
        //init connection (child) cell
        else
        {
            //create/configure
            cell = [self createConnectionCell:event];
        }
    }
    //all other columns
    // init a basic cell
    else
    {
        //init table cell
        cell = [self.outlineView makeViewWithIdentifier:@"simpleCell" owner:self];
        
        //reset text
        ((NSTableCellView*)cell).textField.stringValue = @"";
        
        //set font size
        ((NSTableCellView*)cell).textField.font = [NSFontManager.sharedFontManager convertFont:((NSTableCellView*)cell).textField.font toSize:DEFAULT_FONT_SIZE*(self.zoomScale/100)];
        
        //2nd column: protocol
        if( (YES != isProcessCell) &&
            (tableColumn  == self.outlineView.tableColumns[1]) )
        {
            //set protocol
            ((NSTableCellView*)cell).textField.stringValue = ((Event*)item).provider;
        }
        
        //3rd column: interface
        else if( (YES != isProcessCell) &&
                (tableColumn  == self.outlineView.tableColumns[2]) )
        {
            //set interface
            if(nil != ((Event*)item).interface)
            {
                //interface
                ((NSTableCellView*)cell).textField.stringValue = ((Event*)item).interface;
            }
        }
        
        //4th column: for (tcp) events: state
        else if( (YES != isProcessCell) &&
                 (tableColumn == self.outlineView.tableColumns[3]) )
        {
            //set state
            if(nil != ((Event*)item).tcpState)
            {
                //state
                ((NSTableCellView*)cell).textField.stringValue = ((Event*)item).tcpState;
            }
        }
        
        //5th column: bytes up
        else if(tableColumn == self.outlineView.tableColumns[4])
        {
            //process cell?
            // compute total
            if(YES == isProcessCell)
            {
                //total
                unsigned long total = 0;
                
                //compute all
                for(Event* event in [item allValues])
                {
                    //sum
                    total += event.bytesUp;
                }
                
                //set
                ((NSTableCellView*)cell).textField.stringValue = (0 == total) ? @"0" : [NSByteCountFormatter stringFromByteCount:total countStyle:NSByteCountFormatterCountStyleFile];
            }
            //connection cell
            // just display bytes up for connection
            else
            {
                //set
                ((NSTableCellView*)cell).textField.stringValue = (0 == ((Event*)item).bytesUp) ? @"0" : [NSByteCountFormatter stringFromByteCount:((Event*)item).bytesUp countStyle:NSByteCountFormatterCountStyleFile];
            }
        }
        
        //6th column: bytes down
        else if(tableColumn == self.outlineView.tableColumns[5])
        {
            //process cell?
            // compute total
            if(YES == isProcessCell)
            {
                //total
                unsigned long total = 0;
                
                //compute all
                for(Event* event in [item allValues])
                {
                    //sum
                    total += event.bytesDown;
                }
                
                //set
                ((NSTableCellView*)cell).textField.stringValue = (0 == total) ? @"0" : [NSByteCountFormatter stringFromByteCount:total countStyle:NSByteCountFormatterCountStyleFile];
            }
            //connection cell
            // just display bytes down for connection
            else
            {
                //set bytes down
                ((NSTableCellView*)cell).textField.stringValue = (0 == ((Event*)item).bytesDown) ? @"0" : [NSByteCountFormatter stringFromByteCount:((Event*)item).bytesDown countStyle:NSByteCountFormatterCountStyleFile];
            }
        }
    }
    
bail:
    
    return cell;

}

//create & customize process cell
// this are the root cells,
-(NSTableCellView*)createProcessCell:(Process*)process
{
    //item cell
    NSTableCellView* processCell = nil;
    
    //process name + pid
    NSString* name = nil;
    
    //process path
    NSString* path = nil;
    
    //sub text
    NSTextField* subText = nil;
    
    //create cell
    processCell = [self.outlineView makeViewWithIdentifier:@"processCell" owner:self];
    
    //generate icon
    if(nil == process.binary.icon)
    {
        //generate
        [process.binary getIcon];
    }
    
    //set image
    processCell.imageView.image = process.binary.icon;
    
    //init process name/pid
    name = [NSString stringWithFormat:@"%@ (pid: %d)", (nil != process.binary.name) ? process.binary.name : @"unknown", process.pid];
    
    //set font size
    processCell.textField.font = [NSFontManager.sharedFontManager convertFont:processCell.textField.font toSize:DEFAULT_FONT_SIZE*(self.zoomScale/100)];
  
    //set main text (process name+pid)
    processCell.textField.stringValue = name;

    //init process path
    path = (nil != process.binary.path) ? process.binary.path : @"unknown";
    
    //grab sub text
    subText = [processCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG];
    
    //scale text
    subText.font = [NSFontManager.sharedFontManager convertFont:subText.font toSize:(DEFAULT_FONT_SIZE-5)*(self.zoomScale/100)];
    
    //set sub text (process path)
    subText.stringValue = path;
    
    //set detailed text color to gray
    ((NSTextField*)[processCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG]).textColor = [NSColor secondaryLabelColor];
    
    return processCell;
}

//create & customize connection cell
-(NSTableCellView*)createConnectionCell:(Event*)event
{
    //item cell
    NSTableCellView* cell = nil;
    
    //local address or host
    NSString* localAddress = nil;
    
    //remote address or host
    NSString* remoteAddress = nil;
    
    //create cell
    cell = [self.outlineView makeViewWithIdentifier:@"simpleCell" owner:self];
    
    //reset text
    cell.textField.stringValue = @"";
    
    //set font size
    cell.textField.font = [NSFontManager.sharedFontManager convertFont:cell.textField.font toSize:DEFAULT_FONT_SIZE*(self.zoomScale/100)];
    
    //init local address
    localAddress = event.localAddress[KEY_ADDRRESS];
    
    //have local name?
    if(0 != [event.localAddress[KEY_HOST_NAME] length])
    {
        //set name
        localAddress = event.localAddress[KEY_HOST_NAME];
    }

    //no remote addr/port for listen
    if(YES == [event.tcpState isEqualToString:@"Listen"])
    {
        //set main text
        cell.textField.stringValue = [NSString stringWithFormat:@"%@:%@", localAddress, event.localAddress[KEY_PORT]];
    }
    
    //no remote addr/port for udp
    else if(YES == [event.provider isEqualToString:@"UDP"])
    {
        //set main text
        cell.textField.stringValue = [NSString stringWithFormat:@"%@:%@ →", localAddress, event.localAddress[KEY_PORT]];
    }
    //show remote addr/port for all others...
    else
    {
        //default
        remoteAddress = event.remoteAddress[KEY_ADDRRESS];
        
        //have remote name?
        // if so, use it here
        if(0 != [event.remoteAddress[KEY_HOST_NAME] length])
        {
            //set name
            remoteAddress = event.remoteAddress[KEY_HOST_NAME];
        }
        
        //set main text
        cell.textField.stringValue = [NSString stringWithFormat:@"%@:%@ → %@:%@", localAddress, event.localAddress[KEY_PORT], remoteAddress, event.remoteAddress[KEY_PORT]];
    }

    return cell;
}

//method to toggle apple procs
// filter, then reload all items
-(void)toggleAppleProcs {
    
    //call into filter
    @synchronized (self)
    {
        //filter
        self.processedItems = [self filter];
        
        //reload
        [self.outlineView reloadData];
        
        //default to all expanded
        [self.outlineView expandItem:nil expandChildren:YES];
        
        //scroll to top
        [self.outlineView scrollRowToVisible:0];
        
        //select top row
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    
    return;
}

//button handler
// save, open product url, etc...
-(IBAction)buttonHandler:(id)sender {
    
    //button
    NSButton* button = ((NSButton*)sender);
    
    //switch on action
    switch(button.tag)
    {
        //save
        case BUTTON_SAVE:
        {
            //save results
            [self saveResults];
            
            break;
        }
            
        //prefs
        case BUTTON_PREFS:
        {
            //show prefs
            [((AppDelegate*)NSApplication.sharedApplication.delegate) showPreferences:nil];
            
            break;
        }
            
        //logo
        case BUTTON_LOGO:
        {
            //open webpage
            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:PRODUCT_URL]];
            
            break;
        }
            
        //expand
        case BUTTON_EXPAND:
        {
            //expand
            [self expandAll];
            break;
        }
        
        //collapse
        case BUTTON_COLLAPSE:
        {
            //collapse
            [self collapseAll];
            break;
        }
            
        default:
            break;
    }
    
    return;
}

//map column id to index
-(NSUInteger)columnIDToIndex:(NSString*)columnID
{
    //index
    NSUInteger index = 0;
    
    //map
    for(int i=0; i<self.outlineView.tableColumns.count; i++)
    {
        //match?
        if(YES == [self.outlineView.tableColumns[i].identifier isEqualToString:columnID])
        {
            //save
            index = i;
            
            //done
            break;
        }
    }
    
    return index;
}

//sort
-(void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    //sorted events
    __block OrderedDictionary* sortedEvents = nil;
    
    //column
    NSUInteger column = 0;
    
    //ascending?
    BOOL ascending = NO;
    
    //grab column
    column = [self columnIDToIndex:outlineView.sortDescriptors.firstObject.key];
    
    //ascending?
    ascending = outlineView.sortDescriptors.firstObject.ascending;
    
    //sort in background
    // then update table on main thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
        //sort
        sortedEvents = sortEvents(self.processedItems, column, ascending);
        
        //update table on main thread
        dispatch_async(dispatch_get_main_queue(),
        ^{
            //update table
            [self update:sortedEvents expand:NO reset:YES];
                    
        });
    });
    
    return;
}

//(original) items is an array of arrays
// each array contains Event objs, per process
-(OrderedDictionary*)filter
{
    //filtered items
    OrderedDictionary* results = nil;
    
    //process
    Process* process = nil;
    
    //events (per process)
    OrderedDictionary* events = nil;
    
    //event
    Event* event = nil;
    
    //sanity check
    if(0 == self.items.count)
    {
        //bail
        goto bail;
    }
    
    //init
    results = [[OrderedDictionary alloc] init];
    
    //filter (hide) apple processes?
    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_APPLE])
    {
        //sanity check
        if(0 == self.items.count)
        {
            //bail
            goto bail;
        }
        
        //process all items
        for(NSInteger i=0; i<self.items.count; i++)
        {
            //pid
            NSNumber* pid = [self.items keyAtIndex:i];
            
            //extract
            OrderedDictionary* events = self.items[pid];
            
            //grab process from first event obj
            process = ((Event*)[[events allValues] firstObject]).process;
            
            //skip apple processes
            if( (noErr == [process.signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
                (Apple == [process.signingInfo[KEY_SIGNATURE_SIGNER] intValue]) )
            {
                //skip
                continue;
            }
            
            //cups is apple,
            // but owned by root so we can't check it's signature (but it's SIP protected)
            if(YES == [process.binary.path isEqualToString:CUPS])
            {
                //skip
                continue;
            }
            
            //add (only) non-apple procs
            [results setObject:self.items[pid] forKey:pid];
        }
    }
    //don't filter apple, so grab all
    else
    {
        //all
        results = [self.items copy];
    }
    
    //sanity check
    if(0 == results.count)
    {
        //bail
        goto bail;
    }
    
    //hide (ignore) local connections?
    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_LOCAL])
    {
        //remove any items that are local connection
        for(NSInteger i = results.count-1; i >= 0; i--)
        {
            //grab events (for process)
            events = [[results objectForKey:[results keyAtIndex:i]] copy];
            if(0 == events.count)
            {
                //skip
                continue;
            }
            
            //check all (per) process events
            // remove any events that are local
            for(NSInteger j = events.count-1; j >= 0; j--)
            {
                //grab event
                event = [events objectForKey:[events keyAtIndex:j]];
                
                //interface match?
                // for now, check if starts with "lo"
                if(YES == [event.interface hasPrefix:@"lo"])
                {
                    //remove
                    [events removeObjectForKey:[events keyAtIndex:j]];
                }
            }
            
            //all (per-process) events were local?
            // remove entire process from results
            if(0 == events.count)
            {
                //remove
                [results removeObjectForKey:[results keyAtIndex:i]];
            }
            //otherwise add
            else
            {
                //add
                [results setObject:events forKey:[results keyAtIndex:i]];
            }
        }
    }
    
    //search field blank?
    // all done filtering
    if(0 == self.filterString.length)
    {
        //done!
        goto bail;
    }
    
    //apply search field
    // remove any items that *don't* match
    for(NSInteger i = results.count-1; i >= 0; i--)
    {
        //grab events (for process)
        events = [[results objectForKey:[results keyAtIndex:i]] copy];
        if(0 == events.count)
        {
            //skip
            continue;
        }
        
        //search all (per) process events
        // remove any events that don't match
        for(NSInteger j = events.count-1; j >= 0; j--)
        {
            //grab event
            event = [events objectForKey:[events keyAtIndex:j]];
            
            //no match?
            // remove event
            if(YES != [event matches:self.filterString])
            {
                //remove
                [events removeObjectForKey:[events keyAtIndex:j]];
            }
        }
        
        //no (per-process) events matched?
        // remove entire process from results
        if(0 == events.count)
        {
            //remove
            [results removeObjectForKey:[results keyAtIndex:i]];
        }
        //otherwise add
        else
        {
            //add
            [results setObject:events forKey:[results keyAtIndex:i]];
        }
    }
    
bail:
    
    return results;
}

//invoked when user clicks 'save' icon
// show popup that allows user to save results
-(void)saveResults
{
    //save panel
    NSSavePanel *panel = nil;
    
    //results
    __block NSMutableArray* results;
    
    //output
    // connections, as json
    __block NSMutableString* output = nil;
    
    //alert
    __block NSAlert* popup = nil;
    
    //error
    __block NSError* error = nil;
    
    //create panel
    panel = [NSSavePanel savePanel];
    
    //suggest file name
    [panel setNameFieldStringValue:@"netiquette.json"];
    
    //show panel
    // completion handler invoked when user clicks 'Ok'
    [panel beginWithCompletionHandler:^(NSInteger result)
    {
         //only need to handle 'ok'
         if(NSModalResponseOK == result)
         {
             //alloc results
             results = [NSMutableArray array];
             
             //alloc alert
             popup = [[NSAlert alloc] init];
             
             //add default button
             [popup addButtonWithTitle:@"Ok"];
             
             //format results
             // convert to JSON
             output = formatResults(self.processedItems, [NSUserDefaults.standardUserDefaults boolForKey:PREFS_HIDE_APPLE]);
             
             //save JSON to disk
             // display results in popup
             if(YES != [output writeToURL:[panel URL] atomically:NO encoding:NSUTF8StringEncoding error:&error])
             {
                 //set error msg
                 popup.messageText = @"ERROR: Failed To Save Output";
                 
                 //set error details
                 popup.informativeText = [NSString stringWithFormat:@"Details: %@", error];
             }
             //saved ok
             // just show msg
             else
             {
                 //set msg
                 popup.messageText = @"Succesfully Saved Output";
                 
                 //set details
                 popup.informativeText = [NSString stringWithFormat:@"File: %s", [[panel URL] fileSystemRepresentation]];
             }
            
             //show popup
             [popup runModal];
         }
         
     }];
    
bail:
    
    return;
}

//just reload
// but will (re)apply prefs
-(void)refresh
{
    //update
    [self update:self.items expand:NO reset:NO];
    
    return;
}

//filter (search box) handler
// just call into update method (which filters, etc)
-(IBAction)filterConnections:(id)sender
{
    //save filter string
    self.filterString =  self.filterBox.stringValue;
    
    //update
    [self update:self.items expand:YES reset:YES];
    
    //force an expand all
    // any matched item(s) might otherwise be hidden...
    [self expandAll];
    
    return;
}

//expand all
-(void)expandAll
{
    //expand
    [self.outlineView expandItem:nil expandChildren:YES];
    
    //scroll to top
    [self.outlineView scrollRowToVisible:0];
    
    //select top row
    [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    return;
}

//collapse all
-(void)collapseAll
{
    //collapse
    [self.outlineView collapseItem:nil collapseChildren:YES];
    
    //scroll to top
    [self.outlineView scrollRowToVisible:0];
    
    //select top row
    [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    return;
}

//reset
-(void)zoomReset
{
    //enable zoom in
    [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomInMenuItem state:NSControlStateValueOn];
    
    //enable zoom out
    [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomOutMenuItem state:NSControlStateValueOn];
    
    //reset
    self.zoomScale = 100.0f;
    self.outlineView.rowHeight = DEFAULT_ROW_HEIGHT;
    
    //update/reload
    [self update:self.items expand:NO reset:NO];
    
    return;
}

//zoom in
-(void)zoomIn
{
    //always enable zoom out
    // as we're zooming in...
    [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomOutMenuItem state:NSControlStateValueOn];
    
    //don't zoom in too much
    if(self.zoomScale >= (100 + MAX_ZOOM_SCALE))
    {
        return;
    }
    
    //inc
    self.zoomScale += 5.0f;
    
    //set row height
    self.outlineView.rowHeight = DEFAULT_ROW_HEIGHT*(self.zoomScale/100);
    
    //update/reload
    [self update:self.items expand:NO reset:NO];
    
    //hit max?
    // disable menu option
    if(self.zoomScale >= (100 + MAX_ZOOM_SCALE))
    {
        //disable zoom in
        [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomInMenuItem state:NSControlStateValueOff];
    }
    
    return;
}

//zoom out
-(void)zoomOut
{
    //always enable zoom in
    // as we're zooming out...
    [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomInMenuItem state:NSControlStateValueOn];
    
    //don't zoom out too much
    if(self.zoomScale <= (100 - MAX_ZOOM_SCALE))
    {
        return;
    }
    
    //dec
    self.zoomScale -= 5.0f;
    
    //set row height
    self.outlineView.rowHeight = DEFAULT_ROW_HEIGHT*(self.zoomScale/100);
    
    //update/reload
    [self update:self.items expand:NO reset:NO];
    
    //hit min?
    // disable menu option
    if(self.zoomScale <= (100 - MAX_ZOOM_SCALE))
    {
        //disable zoom out
        [((AppDelegate*)NSApplication.sharedApplication.delegate) toggleMenuItem:((AppDelegate*)NSApplication.sharedApplication.delegate).zoomOutMenuItem state:NSControlStateValueOff];
    }
    
    return;
}

@end
