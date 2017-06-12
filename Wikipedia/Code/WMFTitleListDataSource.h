@import Foundation;
@class MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFTitleListDataSource

@property (nonatomic, strong, readonly) NSArray<NSURL *> *urls;

- (NSUInteger)titleCount;

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath *)indexPath;

@optional

- (void)deleteArticleAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteAll;

@end

NS_ASSUME_NONNULL_END
