
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleListDataSource <NSObject>

- (nullable NSString*)displayTitle;

- (NSUInteger)articleCount;
- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;

@optional
- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END