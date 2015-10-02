//
//  UIViewController+WMFSearchButton.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WMFArticleSelectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKSite, MWKDataStore, WMFSearchViewController;

@protocol WMFSearchPresentationDelegate <WMFArticleSelectionDelegate>

- (MWKDataStore*)dataStore;

@optional

- (MWKSite*)searchSite;

@end

@interface UIViewController (WMFSearchButton)

/**
 *  Standard way of creating a search button for installation in the receiver's toolbar or navigation bar.
 *
 *  @param delegate The delegate which provides data needed to create the search view controller.
 *
 *  @return A new bar button item which will call @c wmf_presentSearchViewController: when pressed.
 */
- (UIBarButtonItem*)wmf_searchBarButtonItemWithDelegate:(UIViewController<WMFSearchPresentationDelegate>*)delegate;

/**
 *  Present @c searchViewController as a result of the search button being pressed.
 *
 *  The default implementation uses a custom modal transition.
 *
 *  @param searchViewController A new search view controller which was created with the dependencies provided by
 *                              the delegate given to @c wmf_searchBarButtonItemWithDelegate:.
 */
- (void)wmf_presentSearchViewController:(UIViewController*)searchViewController;

@end

NS_ASSUME_NONNULL_END
