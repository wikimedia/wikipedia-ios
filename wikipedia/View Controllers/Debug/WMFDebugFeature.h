//
//  WMFDebugFeature.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol WMFDebugTableViewDelegate <NSObject>

- (void)didSelectRow:(NSUInteger)row;

- (void)applyCellConfigurationToTable:(UITableView*)tableView;

@end

@protocol WMFDebugTableViewDataSource <NSObject>

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString*)headerTitle;

- (NSInteger)numberOfRows;

@end

@protocol WMFDebugFeature <NSObject>

- (BOOL)isEnabled;

- (id<WMFDebugTableViewDataSource>)debugViewDataSource;

- (id<WMFDebugTableViewDelegate>)debugViewDelegate;

@end
