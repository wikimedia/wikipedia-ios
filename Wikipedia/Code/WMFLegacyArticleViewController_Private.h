#import "WMFLegacyArticleViewController.h"

@class WMFTableOfContentsViewController, LegacyWebViewController;

typedef NS_ENUM(NSInteger, WMFArticleFooterViewIndex) {
    WMFArticleFooterViewIndexAboutThisArticle = 0,
    WMFArticleFooterViewIndexReadMore = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface WMFLegacyArticleViewController (WMFPrivate)

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle *article;

// Children
@property (nonatomic, strong, nullable) WMFTableOfContentsViewController *tableOfContentsViewController;
@property (nonatomic, strong) LegacyWebViewController *webViewController;

@end

NS_ASSUME_NONNULL_END
