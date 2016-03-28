
#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"
#import "WMFArticleViewController.h"

@class MWKTitle, MWKDataStore;
@class WMFTableOfContentsViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Must be used within a UINavigationController
 */
@interface WMFArticleBrowserViewController : UIViewController

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

- (MWKTitle*)titleOfCurrentArticle;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Create
 *
 *  @param dataStore The data store to use to create WMFArticleViewControllers
 *
 *  @return The WMFArticleBrowserViewController
 */
- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

/**
 *  Convienence, Creates a UINavigationController with a WMFArticleBrowserViewController as the rootViewController
 *
 *  @param dataStore The datastore to used to create WMFArticleViewControllers
 *
 *  @return The navigationController
 */
+ (WMFArticleBrowserViewController*)browserViewControllerWithDataStore:(MWKDataStore*)dataStore;

/**
 *  Convienence, The same as above, additionally set the first article with the given title
 *
 *  @param dataStore The datastore to used to create WMFArticleViewController
 *  @param title                 The title for the article
 *  @param restoreScrollPosition Set to YES to restore the last scroll position of the article
 *
 *  @return The navigationController
 */
+ (WMFArticleBrowserViewController*)browserViewControllerWithDataStore:(MWKDataStore*)dataStore articleTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition;

/**
 *  Convienence ,The same as above, instead setting the first article with the given article view controller
 *
 *  @param viewController The viewcontroller loaded with the first article to didplay
 *
 *  @return The navigationController
 */
+ (WMFArticleBrowserViewController*)browserViewControllerWithArticleViewController:(WMFArticleViewController*)viewController;



- (void)pushArticleWithTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated;

- (void)pushArticleWithTitle:(MWKTitle*)title animated:(BOOL)animated;

- (void)pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated;


@end


@interface UIViewController (WMFArticlePresentation)

+ (void)wmf_setSplitViewController:(UISplitViewController*)splitViewController;

- (void)wmf_pushArticleWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated;

- (void)wmf_pushArticleWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore animated:(BOOL)animated;

- (void)wmf_pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated;

@end


@interface WMFArticleBrowserViewController ()

// Data
@property (nonatomic, strong, readonly, nullable) MWKArticle* currentArticle;

@end



NS_ASSUME_NONNULL_END