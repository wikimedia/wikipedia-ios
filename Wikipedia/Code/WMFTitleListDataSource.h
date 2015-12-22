#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "WMFAnalyticsLogging.h"
#import "UIViewController+WMFEmptyView.h"

NS_ASSUME_NONNULL_BEGIN
@class MWKSavedPageList;

@protocol WMFTitleListDataSource <WMFAnalyticsLogging>

- (nullable NSString*)displayTitle;

@property (nonatomic, strong, readonly) NSArray* titles;

- (NSUInteger)titleCount;

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;

- (MWKHistoryDiscoveryMethod)discoveryMethod;

@optional

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)estimatedItemHeight;

- (WMFEmptyViewType)emptyViewType;

@end

@protocol WMFArticleDeleteAllDataSource <NSObject>

- (BOOL)showsDeleteAllButton;

- (NSString*)deleteAllConfirmationText;

- (NSString*)deleteText;

- (NSString*)deleteCancelText;

- (void)deleteAll;

@end

@protocol WMFArticleListDynamicDataSource <WMFTitleListDataSource>

- (void)startUpdating;

- (void)stopUpdating;

@end

NS_ASSUME_NONNULL_END