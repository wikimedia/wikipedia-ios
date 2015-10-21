//
//  UIViewController+WMFSearchButton.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFSearchButton.h"
#import "WMFSearchViewController.h"
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>
#import "SessionSingleton.h"
#import "UIViewController+WMFArticlePresentation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFSearchButton)

- (UIBarButtonItem*)wmf_searchBarButtonItemWithDelegate:(UIViewController<WMFSearchPresentationDelegate>*)delegate {
    @weakify(self);
    @weakify(delegate);
    return [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"search"]
                                               style:UIBarButtonItemStylePlain
                                             handler:^(id sender) {
        @strongify(self);
        @strongify(delegate);
        if (!delegate || !self) {
            return;
        }

        MWKSite* searchSite;
        if ([delegate respondsToSelector:@selector(searchSite)]) {
            searchSite = [delegate searchSite];
        } else {
            // if the delegate doesn't have a specific site we should search from, default to the user's setting
            searchSite = [[SessionSingleton sharedInstance] searchSite];
        }

        WMFSearchViewController* searchVC =
            [WMFSearchViewController searchViewControllerWithSite:searchSite
                                                        dataStore:[delegate searchDataStore]];
        searchVC.searchResultDelegate = delegate;
        [self presentViewController:searchVC animated:YES completion:nil];
    }];
}

@end

NS_ASSUME_NONNULL_END
