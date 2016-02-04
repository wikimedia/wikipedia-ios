@import UIKit;

@class MWKSite;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

#import "UIViewController+WMFSearch.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UITableViewController<WMFSearchPresentationDelegate>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (void)setSearchSite:(MWKSite* _Nonnull)searchSite dataStore:(MWKDataStore* _Nonnull)dataStore;

@end

NS_ASSUME_NONNULL_END