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

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_presentTitle:(MWKTitle*)title
         discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
               dataStore:(MWKDataStore*)dataStore {
    MWKArticle* article = [dataStore articleWithTitle:title];
    [self wmf_presentArticle:article discoveryMethod:discoveryMethod];
}

- (void)wmf_presentArticle:(MWKArticle*)article
           discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSAssert(article.dataStore, @"Can't present an article w/o a data store!");
    WMFArticleContainerViewController* articleContainerVC = [[WMFArticleContainerViewController alloc] init];
    articleContainerVC.article = article;
    [article.dataStore.userDataStore.historyList addPageToHistoryWithTitle:article.title discoveryMethod:discoveryMethod];
    [article.dataStore.userDataStore.historyList save];
    [self.navigationController pushViewController:articleContainerVC animated:YES];
}

@end
