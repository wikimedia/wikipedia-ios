@import UIKit;
#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class MWKTitle;
@class MWKArticle;
@class WMFShareFunnel;
@class WMFArticleViewController;

NS_ASSUME_NONNULL_BEGIN


@protocol WMFArticleViewControllerDelegate <NSObject>

- (void)articleControllerDidTapShareSelectedText:(WMFArticleViewController*)controller;

- (void)articleControllerDidLoadArticle:(WMFArticleViewController*)controller;

@end


/**
 *  View controller responsible for displaying article content.
 */
@interface WMFArticleViewController : UIViewController<WMFAnalyticsLogging>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

@property (nonatomic, strong, readonly, nullable) MWKArticle* article;

/**
 *  Set to YES to restore the scroll position
 */
@property (nonatomic, assign) BOOL restoreScrollPositionOnArticleLoad;




@property (nonatomic, weak) id<WMFArticleViewControllerDelegate> delegate;

@property (strong, nonatomic, nullable) WMFShareFunnel* shareFunnel;

@property (strong, nonatomic, nullable) UIProgressView* progressView;

@property (nonatomic) UIEdgeInsets contentInsets;

- (BOOL)canRefresh;
- (BOOL)canShare;
- (BOOL)hasLanguages;
- (BOOL)hasTableOfContents;

- (void)fetchArticleIfNeeded;

- (NSString*)shareText;

@end

NS_ASSUME_NONNULL_END
