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
#import "WikipediaAppUtils.h"

@interface AppDelegate (DataMigrationProgressDelegateImpl)
<DataMigrationProgressDelegate>
@end

@implementation AppDelegate (DataMigrationProgressDelegate)

- (BOOL)presentDataMigrationViewControllerIfNeeded {
    if ([DataMigrationProgressViewController needsMigration]) {
        #warning TODO: localize
        UIAlertView* dialog =
            [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"migration-prompt-title", nil)
                                       message:MWLocalizedString(@"migration-prompt-message", nil)
                                      delegate:self
                             cancelButtonTitle:MWLocalizedString(@"migration-skip-button-title", nil)
                             otherButtonTitles:MWLocalizedString(@"migration-confirm-button-title", nil), nil];
        dialog.delegate = self;
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
