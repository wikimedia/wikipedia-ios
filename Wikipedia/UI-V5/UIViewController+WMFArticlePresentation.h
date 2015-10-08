//
//  UIViewController+WMFArticlePresentation.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKTitle, MWKArticle, MWKSavedPageList, MWKHistoryList, MWKDataStore;

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
- (void)wmf_presentTitle:(MWKTitle*)title
         discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
               dataStore:(MWKDataStore*)dataStore;

/**
 *  Default way to present an article.
 *
 *  Creates and shows a new view controller after injecting it with the given dependencies.
 *
 *  @param article          The article to present, if not complete it will be fetched from the network.
 *  @param discoveryMethod  How the article was discovered.
 */
- (void)wmf_presentArticle:(MWKArticle*)article discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

@end

NS_ASSUME_NONNULL_END
