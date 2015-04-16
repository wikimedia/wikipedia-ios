//
//  AppDelegate+DataMigrationProgressDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (DataMigrationProgressDelegate)

/**
 * Presents the data migration UX if there is old data present.
 * @return `YES` if the migration flow was started, otherwise `NO`.
 */
- (BOOL)presentDataMigrationViewControllerIfNeeded;

@end
