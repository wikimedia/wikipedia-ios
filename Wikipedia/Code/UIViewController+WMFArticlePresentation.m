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
#import "WMFArticleViewController.h"
#import "PiwikTracker+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore {
    [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:discoveryMethod dataStore:dataStore animated:YES];
}

- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore
                                      animated:(BOOL)animated {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    WMFArticleViewController* articleContainerVC =
        [[WMFArticleViewController alloc] initWithArticleTitle:title
                                                              dataStore:dataStore
                                                        discoveryMethod:discoveryMethod];
    [self wmf_pushArticleViewController:articleContainerVC];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController*)articleViewController {
    [self wmf_pushArticleViewController:articleViewController animated:YES];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController*)articleViewController animated:(BOOL)animated {
    NSAssert(self.navigationController, @"Illegal attempt to push article %@ from %@ without a navigation controller.",
             articleViewController,
             self);
    id<WMFAnalyticsLogging> source = [self conformsToProtocol:@protocol(WMFAnalyticsLogging)] ? (id<WMFAnalyticsLogging>)self : nil;

    [[PiwikTracker sharedInstance] wmf_logViewForTitle:[articleViewController articleTitle] fromSource:source];
    [self.navigationController pushViewController:articleViewController animated:animated];

    //Delay this so any visual updates to lists are postponed until the article after the article is displayed
    //Some lists (like history) will show these artifacts as the push navigation is occuring.
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        MWKHistoryList* historyList = articleViewController.dataStore.userDataStore.historyList;
        [historyList addPageToHistoryWithTitle:articleViewController.articleTitle
                               discoveryMethod:articleViewController.discoveryMethod];
        [historyList save];
    });
}

@end

NS_ASSUME_NONNULL_END
