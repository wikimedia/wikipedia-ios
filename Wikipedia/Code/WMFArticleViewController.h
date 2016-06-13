@import UIKit;
#import "WMFAnalyticsLogging.h"
#import "MWKArticle.h"

@class MWKDataStore;
@class MWKTitle;
@class WMFShareFunnel;
@class WMFArticleViewController;

NS_ASSUME_NONNULL_BEGIN


@protocol WMFArticleViewControllerDelegate <NSObject>

- (void)articleController:(WMFArticleViewController*)controller didUpdateArticleLoadProgress:(CGFloat)progress animated:(BOOL)animated;

- (void)articleControllerDidLoadArticle:(WMFArticleViewController*)controller;

- (void)articleControllerDidFailToLoadArticle:(WMFArticleViewController*)controller;

@end

/**
 *  View controller responsible for displaying article content.
 */
@interface WMFArticleViewController : UIViewController<WMFAnalyticsContextProviding, WMFAnalyticsViewNameProviding>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

@property (nonatomic, strong, readonly, nullable) MWKArticle* article;

@property (nonatomic, weak) id<WMFArticleViewControllerDelegate> delegate;

@end


@interface WMFArticleViewController (WMFBrowserViewControllerInterface)


@property (strong, nonatomic, nullable, readonly) WMFShareFunnel* shareFunnel;

- (BOOL)canRefresh;
- (BOOL)canShare;
- (BOOL)hasLanguages;
- (BOOL)hasTableOfContents;
- (BOOL)hasReadMore;
- (BOOL)hasAboutThisArticle;

- (void)fetchArticleIfNeeded;

- (void)shareArticleFromButton:(nullable UIBarButtonItem*)button;

@end


@interface WMFArticleViewController (WMFSubclasses)

@property (nonatomic, strong, readonly) UIBarButtonItem* saveToolbarItem;
@property (nonatomic, strong, readonly) UIBarButtonItem* languagesToolbarItem;
@property (nonatomic, strong, readonly) UIBarButtonItem* shareToolbarItem;
@property (nonatomic, strong, readonly) UIBarButtonItem* fontSizeToolbarItem;
@property (nonatomic, strong, readonly) UIBarButtonItem* tableOfContentsToolbarItem;


- (NSArray<UIBarButtonItem*>*)articleToolBarItems;

- (void)updateToolbarItemEnabledState;



@end


NS_ASSUME_NONNULL_END
