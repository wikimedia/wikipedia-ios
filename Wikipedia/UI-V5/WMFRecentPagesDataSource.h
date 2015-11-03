#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKHistoryList, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRecentPagesDataSource : SSSectionedDataSource<WMFTitleListDataSource>

@property (nonatomic, strong, readonly) NSArray* articles;

@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

- (nonnull instancetype)initWithRecentPagesList:(MWKHistoryList*)recentPages savedPages:(MWKSavedPageList*)savedPages;

@end


NS_ASSUME_NONNULL_END
