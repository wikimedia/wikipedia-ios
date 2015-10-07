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
 *  Macro which fills passes the receiver's @c dataStore etc. as parameters when presenting an article.
 *
 *  @param article         The article to present.
 *  @param discoveryMethod How the article was discovered.
 *
 *  @see @c wmf_presentArticle:discoveryMethod:dataStore:recentPages:savedPages:
 */
#define presentArticleWithDiscoveryMethod(article, method) \
    _presentArticleOrTitleWithDiscoveryMethod(Article, article, method)

/**
 *  Macro which fills passes the receiver's @c dataStore etc. as parameters when presenting a title.
 *
 *  @param title           The title to present.
 *  @param discoveryMethod How the article was discovered.
 *
 *  @see @c wmf_presentTitle:discoveryMethod:dataStore:recentPages:savedPages:
 */
#define presentTitleWithDiscoveryMethod(title, method) \
    _presentArticleOrTitleWithDiscoveryMethod(Title, title, method)

#define _presentArticleOrTitleWithDiscoveryMethod(ArticleOrTitle, obj, method) \
    [self \
     wmf_present ## ArticleOrTitle : (obj) \
     discoveryMethod : (method) \
     dataStore : self.dataStore \
     recentPages : self.recentPages \
     savedPages : self.savedPages]

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
 *  @param recentPages      The history list which will be updated after the title is presented.
 *  @param savedPages       The saved page list used to derive the saved state for the given title.
 *
 *  @see
 */
- (void)wmf_presentTitle:(MWKTitle*)title
         discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
               dataStore:(MWKDataStore*)dataStore
             recentPages:(MWKHistoryList*)recentPages
              savedPages:(MWKSavedPageList*)savedPages;

/**
 *  Default way to present an article.
 *
 *  Creates and shows a new view controller after injecting it with the given dependencies.
 *
 *  @param article          The article to present, if not complete it will be fetched from the network.
 *  @param discoveryMethod  How the article was discovered.
 *  @param dataStore        The data store the article was read from or should be written to.
 *  @param recentPages      The history list which will be updated after the article is presented.
 *  @param savedPages       The saved page list used to derive the saved state for the given article.
 */
- (void)wmf_presentArticle:(MWKArticle*)article
           discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                 dataStore:(MWKDataStore*)dataStore
               recentPages:(MWKHistoryList*)recentPages
                savedPages:(MWKSavedPageList*)savedPages;

@end

NS_ASSUME_NONNULL_END
