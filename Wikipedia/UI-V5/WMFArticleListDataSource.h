#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"

NS_ASSUME_NONNULL_BEGIN
@class MWKSavedPageList;

@protocol WMFArticleListDataSource <NSObject>

- (nullable NSString*)displayTitle;

@property (nonatomic, strong, readonly) NSArray* articles;

- (NSUInteger) articleCount;
- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)indexPathForArticle:(MWKArticle*)article;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;

- (MWKHistoryDiscoveryMethod)discoveryMethod;

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList;

@optional

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)estimatedItemHeight;

@end

@protocol WMFArticleListDynamicDataSource <WMFArticleListDataSource>

- (void)startUpdating;

- (void)stopUpdating;

@end

NS_ASSUME_NONNULL_END