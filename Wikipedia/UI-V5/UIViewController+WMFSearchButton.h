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

- (MWKDataStore*)searchDataStore;

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
 *  Default implemenation of "commit" for an article from search.
 *
 *  @param articleViewController The view controller to commit.
 *  @param sender                The object that previewed it.
 */
- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender;

@end

NS_ASSUME_NONNULL_END
