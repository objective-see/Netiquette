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

//outline view
@property (weak) IBOutlet NSOutlineView *outlineView;

//original connections
@property(nonatomic, retain)OrderedDictionary* items;

//filtered connections
@property(nonatomic, retain)OrderedDictionary* processedItems;

@property (weak) IBOutlet NSSearchField *filterBox;


//auto-refresh button
@property (weak) IBOutlet NSButton *refreshButton;

//filter apple button
@property (weak) IBOutlet NSButton *filterButton;

@property (nonatomic, retain)NSMutableDictionary* collapsedItems;


/* METHODS */

//update table
-(void)update:(OrderedDictionary*)updatedItems;

@end

NS_ASSUME_NONNULL_END
