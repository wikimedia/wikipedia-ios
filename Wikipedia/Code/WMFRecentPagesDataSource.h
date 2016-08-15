#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRecentPagesDataSource : SSSectionedDataSource <WMFTitleListDataSource>

@property(nonatomic, strong, readonly) NSArray *articles;

@property(nonatomic, strong, readonly) MWKHistoryList *recentPages;

- (nonnull instancetype)initWithRecentPagesList:(MWKHistoryList *)recentPages;

@end

NS_ASSUME_NONNULL_END
