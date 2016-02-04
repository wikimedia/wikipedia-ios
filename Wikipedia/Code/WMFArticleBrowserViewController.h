
#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"
#import "WMFArticleViewController.h"

@class MWKTitle, MWKDataStore;

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
+ (UINavigationController*)embeddedBrowserViewControllerWithDataStore:(MWKDataStore*)dataStore;

/**
 *  Convienence, The same as above, additionally set the first article with the given title
 *
 *  @param dataStore The datastore to used to create WMFArticleViewController
 *  @param title                 The title for the article
 *  @param restoreScrollPosition Set to YES to restore the last scroll position of the article
 *  @param source                The analytics source
 *
 *  @return The navigationController
 */
+ (UINavigationController*)embeddedBrowserViewControllerWithDataStore:(MWKDataStore*)dataStore articleTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition source:(nullable id<WMFAnalyticsLogging>)source;

/**
 *  Convienence ,The same as above, instead setting the first article with the given article view controller
 *
 *  @param viewController The viewcontroller loaded with the first article to didplay
 *  @param source                The analytics source
 *
 *  @return The navigationController
 */
+ (UINavigationController*)embeddedBrowserViewControllerWithArticleViewController:(WMFArticleViewController*)viewController source:(nullable id<WMFAnalyticsLogging>)source;



- (void)pushArticleWithTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition source:(nullable id<WMFAnalyticsLogging>)source animated:(BOOL)animated;

- (void)pushArticleWithTitle:(MWKTitle*)title source:(nullable id<WMFAnalyticsLogging>)source animated:(BOOL)animated;

- (void)pushArticleViewController:(WMFArticleViewController*)viewController source:(nullable id<WMFAnalyticsLogging>)source animated:(BOOL)animated;


@end


NS_ASSUME_NONNULL_END