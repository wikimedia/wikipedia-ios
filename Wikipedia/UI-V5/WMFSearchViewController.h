
@protocol WMFSearchViewControllerDelegate;

@class MWKSite, MWKDataStore, MWKSavedPageList, MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN
@interface WMFSearchViewController : UIViewController

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKHistoryList* recentPages;

@end

NS_ASSUME_NONNULL_END