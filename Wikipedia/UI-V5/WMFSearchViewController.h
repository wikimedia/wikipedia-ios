
@protocol WMFSearchViewControllerDelegate;

@class MWKSite, MWKDataStore, MWKSavedPageList, MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFSearchState) {
    WMFSearchStateInactive,
    WMFSearchStateActive
};

@interface WMFSearchViewController : UIViewController

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKHistoryList* recentPages;

@property(nonatomic, weak, nullable) id<WMFSearchViewControllerDelegate> delegate;

@property (nonatomic, assign, readonly) WMFSearchState state;

@end


@protocol WMFSearchViewControllerDelegate <NSObject>

- (void)searchController:(WMFSearchViewController*)controller searchStateDidChange:(WMFSearchState)state;

@end

NS_ASSUME_NONNULL_END