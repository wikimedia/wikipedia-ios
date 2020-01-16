@import UIKit;
@import WMF.Swift;
@import WebKit;

@class MWKSection, MWKArticle, WMFPeekHTMLElement, WKWebView, WMFNavigationBar;

typedef NS_ENUM(NSInteger, WMFArticleFooterMenuItem);

@protocol WMFWebViewControllerDelegate;

extern const CGFloat WebViewControllerHeaderImageHeight;

NS_ASSUME_NONNULL_BEGIN

@interface LegacyWebViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, WMFThemeable>

@property (nonatomic, strong, nullable, readonly) MWKArticle *article;
@property (nonatomic, strong, nullable, readonly) NSURL *articleURL;

@property (nonatomic, weak, nullable) id<WMFWebViewControllerDelegate> delegate;

@property (nonatomic, strong, nullable, readonly) WKWebView *webView;

@property (nonatomic) CGFloat contentWidthPercentage;

@property (nonatomic, getter=isHeaderFadingEnabled) BOOL headerFadingEnabled;

@property (nonatomic, readonly) CGFloat marginWidth;

@property (nonatomic, readonly) WMFTheme *theme;

#if DEBUG || TEST
@property (nonatomic, copy, nullable) void (^wkUserContentControllerTestingConfigurationBlock)(WKUserContentController *);
- (void)applyTheme:(WMFTheme *)theme;
#endif

- (void)setArticle:(MWKArticle *_Nullable)article articleURL:(NSURL *)articleURL;

/**
 *  Scroll to the @c anchor provided
 *
 *  @param anchor  The anchor to scroll to.
 *  @param animated Whether or not to animate.
 *  @param completion called when the scroll completes.
 *
 */
- (void)scrollToAnchor:(nullable NSString *)anchor animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)accessibilityCursorToSection:(MWKSection *)section;

- (void)getCurrentVisibleSectionCompletion:(void (^)(MWKSection *_Nullable, NSError *__nullable error))completion;

- (void)getCurrentVisibleFooterIndexCompletion:(void (^)(NSNumber *_Nullable, NSError *__nullable error))completion;

- (CGFloat)currentVerticalOffset;

- (void)setFontSizeMultiplier:(NSNumber *)fontSize;

- (void)showFindInPage;
- (void)hideFindInPageWithCompletion:(nullable dispatch_block_t)completion;

#pragma mark - Header & Footers

@property (nonatomic, strong, nullable) UIView *headerView;

@end

@protocol WMFWebViewControllerDelegate <NSObject>

@property (nonatomic, readonly) WMFNavigationBar *navigationBar;

- (void)webViewController:(LegacyWebViewController *)controller didLoadArticle:(MWKArticle *)article;
- (void)webViewController:(LegacyWebViewController *)controller didLoadArticleContent:(MWKArticle *)article;
- (void)webViewController:(LegacyWebViewController *)controller didTapEditForSection:(MWKSection *)section;
- (void)webViewController:(LegacyWebViewController *)controller didTapOnLinkForArticleURL:(NSURL *)url;
- (void)webViewController:(LegacyWebViewController *)controller didSelectText:(NSString *)text;
- (void)webViewController:(LegacyWebViewController *)controller didTapShareWithSelectedText:(NSString *)text;
- (void)webViewController:(LegacyWebViewController *)controller didTapEditMenuItemInMenuController:(UIMenuController *)menuController;
- (void)webViewController:(LegacyWebViewController *)controller didTapImageWithSourceURL:(NSURL *)imageSourceURL;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)webViewController:(LegacyWebViewController *)controller scrollViewDidScrollToTop:(UIScrollView *)scrollView;
- (BOOL)webViewController:(LegacyWebViewController *)controller scrollViewShouldScrollToTop:(UIScrollView *)scrollView;
- (void)webViewController:(LegacyWebViewController *)controller didTapFooterMenuItem:(WMFArticleFooterMenuItem)item payload:(NSArray *)payload;
- (void)webViewController:(LegacyWebViewController *)controller didTapFooterReadMoreSaveForLaterForArticleURL:(NSURL *)url didSave:(BOOL)didSave;
- (void)webViewController:(LegacyWebViewController *)controller didTapAddTitleDescriptionForArticle:(MWKArticle *)article;
- (void)webViewController:(LegacyWebViewController *)controller didScrollToAnchor:(nullable NSString *)anchor;

@end

NS_ASSUME_NONNULL_END
