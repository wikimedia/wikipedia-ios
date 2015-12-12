//
//  UIViewController+WMFSearchButton.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFSearchButton_Testing.h"
#import "WMFSearchViewController.h"
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>
#import "SessionSingleton.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "MWKSite.h"

NS_ASSUME_NONNULL_BEGIN

static BOOL isSearchPresentationAnimated = YES;

@implementation UIViewController (WMFSearchButton)

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wmfSearchButton_applicationDidEnterBackgroundWithNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wmfSearchButton_applicationDidReceiveMemoryWarningWithNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

+ (void)wmf_setSearchPresentationIsAnimated:(BOOL)animated {
    isSearchPresentationAnimated = animated;
}

+ (void)wmfSearchButton_applicationDidEnterBackgroundWithNotification:(NSNotification*)note {
    [self wmfSearchButton_resetSharedSearchButton];
}

+ (void)wmfSearchButton_applicationDidReceiveMemoryWarningWithNotification:(NSNotification*)note {
    [self wmfSearchButton_resetSharedSearchButton];
}

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

        MWKSite* searchSite = [[SessionSingleton sharedInstance] searchSite];

        if (![searchSite isEqual:_sharedSearchViewController.searchSite]) {
            WMFSearchViewController* searchVC =
                [WMFSearchViewController searchViewControllerWithSite:searchSite
                                                            dataStore:[delegate searchDataStore]];
            _sharedSearchViewController = searchVC;
        }
        _sharedSearchViewController.searchResultDelegate = delegate;
        [self presentViewController:_sharedSearchViewController animated:isSearchPresentationAnimated completion:nil];
    }];
}

@end

NS_ASSUME_NONNULL_END
