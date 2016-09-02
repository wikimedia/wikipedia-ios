#import <SSDataSources/SSDataSources.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFooterMenuDataSource : SSArrayDataSource

@property (nonatomic, strong, nullable) MWKArticle *article;

- (instancetype)initWithArticle:(nullable MWKArticle *)article;

@end

NS_ASSUME_NONNULL_END
