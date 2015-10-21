//
//  UIViewController+WMFArticlePresentation.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFArticlePresentation.h"
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageList.h"
#import "MWKUserDataStore.h"
#import "WMFArticleContainerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    WMFArticleContainerViewController* articleContainerVC =
        [[WMFArticleContainerViewController alloc] initWithArticleTitle:title
                                                              dataStore:dataStore
                                                        discoveryMethod:discoveryMethod];
    [self wmf_pushArticleViewController:articleContainerVC];
}

- (void)wmf_pushArticleViewController:(WMFArticleContainerViewController*)articleViewController {
    MWKHistoryList* historyList = articleViewController.dataStore.userDataStore.historyList;
    [historyList addPageToHistoryWithTitle:articleViewController.articleTitle
                           discoveryMethod:articleViewController.discoveryMethod];
    [historyList save];
    NSAssert(self.navigationController, @"Illegal attempt to push article %@ from %@ without a navigation controller.",
             articleViewController,
             self);
    [self.navigationController pushViewController:articleViewController animated:YES];
}

@end

NS_ASSUME_NONNULL_END
