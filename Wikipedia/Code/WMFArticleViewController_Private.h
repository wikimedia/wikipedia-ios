#import "WMFArticleViewController.h"

@class WMFTableOfContentsViewController, WebViewController;

typedef NS_ENUM(NSInteger, WMFArticleFooterViewIndex) {
    WMFArticleFooterViewIndexAboutThisArticle = 0,
    WMFArticleFooterViewIndexReadMore = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController (WMFPrivate)

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle *article;

// Children
@property (nonatomic, strong, nullable) WMFTableOfContentsViewController *tableOfContentsViewController;
@property (nonatomic, strong) WebViewController *webViewController;

@end

NS_ASSUME_NONNULL_END
