@import UIKit;

@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleTextActivitySource : NSObject <UIActivityItemSource>

- (instancetype)initWithArticle:(MWKArticle *)article shareText:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
