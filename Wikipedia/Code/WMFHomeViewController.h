@import UIKit;

@class MWKSite;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

#import "UIViewController+WMFSearch.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeViewController : UITableViewController<WMFSearchPresentationDelegate>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKHistoryList* recentPages;

@end

NS_ASSUME_NONNULL_END