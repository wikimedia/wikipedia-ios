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

        UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"migrate?"
                                                         message:@"should migrate?"
                                                        delegate:self
                                               cancelButtonTitle:@"cancel migrate"
                                               otherButtonTitles:@"migrate yes", nil];
        
        [dialog show];

        [self transitionToRootViewController:migrationVC animated:NO];
        return YES;
    } else {
        return NO;
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: //cancel migration
            //[migrationVC removeOldData];
            break;
        case 1: // proceed with migration
            
            break;
            
        default:
            break;
    }
}

@end

@implementation AppDelegate (DataMigrationProgressDelegateImpl)

- (void)dataMigrationProgressComplete:(DataMigrationProgressViewController*)viewController {
    [self presentRootViewController:YES withSplash:NO];
}

@end
