//
//  UIViewController+WMFArticlePresentation.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWKHistoryEntry.h"

@class MWKTitle, MWKArticle, MWKSavedPageList, MWKHistoryList, MWKDataStore, WMFArticlePreviewTuple;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticlePreviewingDelegate <NSObject>

- (nullable WMFArticlePreviewTuple*)previewDataForTitleAtPoint:(CGPoint)point inView:(UIView*)view;

- (MWKDataStore*)dataStore;

@end

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


/**
 *  Register for notifications to preview (peek) a title contained in the given view.
 *
 *  @param view     The view in which titles are displayed (e.g. search results).
 *  @param delegate The delegate providing information needed to preview & commit titles.
 */
- (void)wmf_previewTitlesInView:(UIView*)view delegate:(id<WMFArticlePreviewingDelegate>)delegate;

@end

/**
 *  Dummy class for encapsulating the title to preview, and its originating discovery method.
 */
@interface WMFArticlePreviewTuple : NSObject

@property (nonatomic, strong, nonnull) MWKTitle* previewedTitle;
@property (nonatomic, assign) MWKHistoryDiscoveryMethod discoveryMethod;

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

@end

NS_ASSUME_NONNULL_END
