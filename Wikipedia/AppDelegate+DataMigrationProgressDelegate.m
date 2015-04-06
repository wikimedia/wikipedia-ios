//
//  AppDelegate+DataMigrationProgressDelegate.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AppDelegate+DataMigrationProgressDelegate.h"
#import "DataMigrationProgressViewController.h"
#import "UIWindow+WMFMainScreenWindow.h"

@interface AppDelegate (DataMigrationProgressDelegateImpl)
<DataMigrationProgressDelegate>
@end

@implementation AppDelegate (DataMigrationProgressDelegate)

- (BOOL)presentDataMigrationViewControllerIfNeeded {
    DataMigrationProgressViewController* migrationVC = [[DataMigrationProgressViewController alloc] init];
    migrationVC.delegate = self;
    if ([migrationVC needsMigration]) {
        [self transitionToRootViewController:migrationVC animated:NO];
        return YES;
    } else {
        return NO;
    }
}

@end

@implementation AppDelegate (DataMigrationProgressDelegateImpl)

- (void)dataMigrationProgressComplete:(DataMigrationProgressViewController*)viewController {
    [self presentRootViewController:YES withSplash:NO];
}

@end
