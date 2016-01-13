#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "UIViewController+WMFEmptyView.h"

NS_ASSUME_NONNULL_BEGIN
@class MWKSavedPageList;

@protocol WMFTitleListDataSource

@property (nonatomic, strong, readonly) NSArray* titles;

- (NSUInteger)titleCount;

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;

@optional

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

- (void)deleteAll;

@end

@protocol WMFArticleListDynamicDataSource <WMFTitleListDataSource>

- (void)startUpdating;

- (void)stopUpdating;

@end

NS_ASSUME_NONNULL_END