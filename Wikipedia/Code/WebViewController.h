#import <UIKit/UIKit.h>
@import WebKit;

@class MWKSection, MWKArticle, WMFPeekHTMLElement;

typedef NS_ENUM(NSInteger, WMFArticleFooterMenuItem);

@protocol WMFWebViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController <UIWebViewDelegate,
                                                 UIScrollViewDelegate,
                                                 UIGestureRecognizerDelegate,
                                                 UIAlertViewDelegate>

@property (nonatomic, strong, nullable, readonly) MWKArticle *article;
@property (nonatomic, strong, nullable, readonly) NSURL *articleURL;

@property (nonatomic, weak, nullable) id<WMFWebViewControllerDelegate> delegate;

@property (nonatomic, strong, nullable, readonly) WKWebView *webView;

@property (nonatomic) CGFloat contentWidthPercentage;
@property (nonatomic, readonly) CGFloat marginWidth;

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

- (CGFloat)currentVerticalOffset;

- (void)setFontSizeMultiplier:(NSNumber *)fontSize;

- (void)showFindInPage;
- (void)hideFindInPageWithCompletion:(nullable dispatch_block_t)completion;

#pragma mark - Header & Footers

@property (nonatomic, strong, nullable) UIView *headerView;

@end

@protocol WMFWebViewControllerDelegate <NSObject>

- (void)webViewController:(WebViewController *)controller didLoadArticle:(MWKArticle *)article;
- (void)webViewController:(WebViewController *)controller didTapEditForSection:(MWKSection *)section;
- (void)webViewController:(WebViewController *)controller didTapOnLinkForArticleURL:(NSURL *)url;
- (void)webViewController:(WebViewController *)controller didSelectText:(NSString *)text;
- (void)webViewController:(WebViewController *)controller didTapShareWithSelectedText:(NSString *)text;
- (void)webViewController:(WebViewController *)controller didTapImageWithSourceURL:(NSURL *)imageSourceURL;
- (void)webViewController:(WebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller scrollViewDidScrollToTop:(UIScrollView *)scrollView;
- (void)webViewController:(WebViewController *)controller didTapFooterMenuItem:(WMFArticleFooterMenuItem)item;

@end

NS_ASSUME_NONNULL_END
