
@protocol WMFSearchViewControllerDelegate;

@class MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

@property (nonatomic, weak) id searchResultDelegate;

+ (instancetype)searchViewControllerWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END