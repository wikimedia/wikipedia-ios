//
//  UIViewController+WMFArticlePresentation.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WMFArticleSelectionDelegate.h"

@class MWKTitle, MWKArticle, MWKSavedPageList, MWKHistoryList, MWKDataStore, WMFArticleContainerViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Informal protocol for presenting an article.
 *
 *  Allows us to keep the business logic for updating history list centralized and reusable.
 */
@interface UIViewController (WMFArticlePresentation)

/**
 *  Default way to present an article for a given title.
 *
 *  Creates and shows a new view controller after injecting it with the given dependencies.
 *
 *  @param title            The associated article will be retrieved from @c dataStore or fetched from the API.
 *  @param discoveryMethod  How the title was discovered.
 *  @param dataStore        The data store the title will be read from or should be written to.
 */
- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore;

- (void)wmf_pushArticleViewController:(WMFArticleContainerViewController*)articleViewController;

@end

NS_ASSUME_NONNULL_END
