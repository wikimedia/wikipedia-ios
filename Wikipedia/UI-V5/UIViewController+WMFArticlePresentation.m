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
#import "WMFArticleContainerViewController.h"

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_presentTitle:(MWKTitle*)title
         discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
               dataStore:(MWKDataStore*)dataStore
             recentPages:(MWKHistoryList*)recentPages
              savedPages:(MWKSavedPageList*)savedPages {
    MWKArticle* article = [dataStore articleWithTitle:title];
    [self wmf_presentArticle:article
             discoveryMethod:discoveryMethod
                   dataStore:dataStore
                 recentPages:recentPages
                  savedPages:savedPages];
}

- (void)wmf_presentArticle:(MWKArticle*)article
           discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                 dataStore:(MWKDataStore*)dataStore
               recentPages:(MWKHistoryList*)recentPages
                savedPages:(MWKSavedPageList*)savedPages {
    WMFArticleContainerViewController* articleContainerVC =
        [WMFArticleContainerViewController articleContainerViewControllerWithDataStore:article.dataStore
                                                                           recentPages:recentPages
                                                                            savedPages:savedPages];
    articleContainerVC.article = article;
    [recentPages addPageToHistoryWithTitle:article.title discoveryMethod:discoveryMethod];
    [recentPages save];
    [self.navigationController pushViewController:articleContainerVC animated:YES];
}

@end
