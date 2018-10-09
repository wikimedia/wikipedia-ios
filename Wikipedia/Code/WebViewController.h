@import UIKit;
@import WMF.Swift;
@import WebKit;

@class MWKSection, MWKArticle, WMFPeekHTMLElement, WKWebView, WMFNavigationBar;

typedef NS_ENUM(NSInteger, WMFArticleFooterMenuItem);

@protocol WMFWebViewControllerDelegate;

extern const CGFloat WebViewControllerHeaderImageHeight;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, WMFThemeable>

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
 *  Scroll to the @c anchor of the given section.
 *
 *  @param section  The section to scroll to.
 *  @param animated Whether or not to animate.
 *
 *  @see scrollToFragment:animated:
 */
- (void)scrollToSection:(MWKSection *)section animated:(BOOL)animated;

- (void)scrollToFragment:(NSString *)fragment animated:(BOOL)animated;

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

- (void)webViewController:(WebViewController *)controller didLoadArticle:(MWKArticle *)article;
- (void)webViewController:(WebViewController *)controller didTapEditForSection:(MWKSection *)section;
- (void)webViewController:(WebViewController *)controller didTapOnLinkForArticleURL:(NSURL *)url;
- (void)webViewController:(WebViewController *)controller didSelectText:(NSString *)text;
- (void)webViewController:(WebViewController *)controller didTapShareWithSelectedText:(NSString *)text;
- (void)webViewController:(WebViewController *)controller didTapImageWithSourceURL:(NSURL *)imageSourceURL;
- (void)webViewController:(WebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
- (void)webViewController:(WebViewController *)controller scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller scrollViewDidScrollToTop:(UIScrollView *)scrollView;
- (BOOL)webViewController:(WebViewController *)controller scrollViewShouldScrollToTop:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller didTapFooterMenuItem:(WMFArticleFooterMenuItem)item payload:(NSArray *)payload;
- (void)webViewController:(WebViewController *)controller didTapFooterReadMoreSaveForLaterForArticleURL:(NSURL *)url didSave:(BOOL)didSave;
- (void)webViewController:(WebViewController *)controller didTapAddTitleDescriptionForArticle:(MWKArticle *)article;

@end

NS_ASSUME_NONNULL_END
