//
//  UIViewController+WMFSearchButton.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFSearchButton.h"
#import "WMFSearchViewController.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFSearchButton)

- (UIBarButtonItem*)wmf_searchBarButtonItemWithDelegate:(UIViewController<WMFSearchPresentationDelegate>*)delegate {
    @weakify(self);
    @weakify(delegate);
    return [UIBarButtonItem wmf_buttonType:WMFButtonTypeMagnify handler:^(id sender) {
        @strongify(self);
        @strongify(delegate);
        if (!delegate || !self) {
            return;
        }
        UIViewController* searchVC =
            [WMFSearchViewController searchViewControllerWithSite:[delegate site] dataStore:[delegate dataStore]];
        [self wmf_presentSearchViewController:searchVC];
    }];
}

- (void)wmf_presentSearchViewController:(UIViewController*)searchViewController {
    [self presentViewController:searchViewController animated:YES completion:nil];
}

- (void)didSelectTitle:(nullable MWKTitle*)title {
    if (title) {
        // create & present article container
    }
    [self dismissViewControllerAnimated:YES completion:^{
        // push container
    }];
}

@end

NS_ASSUME_NONNULL_END
