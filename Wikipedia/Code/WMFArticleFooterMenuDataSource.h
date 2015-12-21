#import <SSDataSources/SSDataSources.h>

@interface WMFArticleFooterMenuDataSource : SSArrayDataSource

@property (nonatomic, strong, readonly) MWKArticle* article;

- (instancetype)initWithArticle:(MWKArticle*)article;

@end
