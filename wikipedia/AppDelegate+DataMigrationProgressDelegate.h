//
//  AppDelegate+DataMigrationProgressDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (DataMigrationProgressDelegate)

- (BOOL)presentDataMigrationViewControllerIfNeeded;

@end
