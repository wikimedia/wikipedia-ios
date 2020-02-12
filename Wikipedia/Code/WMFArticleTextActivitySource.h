@import UIKit;

@class WMFArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleTextActivitySource : NSObject <UIActivityItemSource>

- (instancetype)initWithArticle:(WMFArticle *)article shareText:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
