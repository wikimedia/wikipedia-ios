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
    if ([DataMigrationProgressViewController needsMigration]) {
        #warning TODO: localize
        UIAlertView* dialog =
            [[UIAlertView alloc] initWithTitle:@"Looks like we have a history!"
                                       message:@"We've made some changes to how data is stored in the app, and need to"
                                                "migrate your data (e.g. saved and recent pages) to the new format."
                                                " This might take a few minutes if you have a lot of data."
                                      delegate:self
                             cancelButtonTitle:@"Delete my data"
                             otherButtonTitles:@"Migrate my data", nil];
        [dialog show];
        return YES;
    } else {
        return NO;
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [DataMigrationProgressViewController removeOldData];
        [self presentRootViewController:YES withSplash:NO];
    } else {
        DataMigrationProgressViewController* migrationVC = [[DataMigrationProgressViewController alloc] init];
        migrationVC.delegate = self;
        [self transitionToRootViewController:migrationVC animated:NO];
    }
}

@end

@implementation AppDelegate (DataMigrationProgressDelegateImpl)

- (void)dataMigrationProgressComplete:(DataMigrationProgressViewController *)viewController {
    [self presentRootViewController:YES withSplash:NO];
}

@end
