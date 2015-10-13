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

- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    MWKHistoryEntry* historyEntry = [dataStore.userDataStore.historyList addPageToHistoryWithTitle:title discoveryMethod:discoveryMethod];
    [dataStore.userDataStore.historyList save];
    
    WMFArticleContainerViewController* articleContainerVC = [[WMFArticleContainerViewController alloc] initWithArticleTitle:title dataStore:dataStore];
    
    [self.navigationController pushViewController:articleContainerVC animated:YES];
}


@end
