//
//  TableViewController.h
//  Netiquette
//
//  Created by Patrick Wardle on 7/20/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "3rd-party/OrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@interface TableViewController : NSOutlineView <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSView *overlay;

//outline view
@property (weak) IBOutlet NSOutlineView *outlineView;

//overlay spinner
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

//overlay msg
@property (weak) IBOutlet NSTextField *activityMessage;

//original connections
@property(nonatomic, retain)OrderedDictionary* items;

//filtered connections
@property(nonatomic, retain)OrderedDictionary* processedItems;

@property (weak) IBOutlet NSSearchField *filterBox;

//auto-refresh button
@property (weak) IBOutlet NSButton *refreshButton;

//resolve names button
@property (weak) IBOutlet NSButton *resolveButton;

//filter apple button
@property (weak) IBOutlet NSButton *filterButton;

@property (nonatomic, retain)NSMutableDictionary* collapsedItems;


/* METHODS */

//update table
-(void)update:(OrderedDictionary*)updatedItems reset:(BOOL)reset;

//map column id to index
-(NSUInteger)columnIDToIndex:(NSString*)columnID;

@end

NS_ASSUME_NONNULL_END
