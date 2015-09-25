
@protocol WMFSearchViewControllerDelegate;

@class MWKSite, MWKUserDataStore;

NS_ASSUME_NONNULL_BEGIN
@interface WMFSearchViewController : UIViewController

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKUserDataStore* userDataStore;

- (instancetype)initWithSite:(MWKSite*)site userDataStore:(MWKUserDataStore*)userDataStore;

@end

NS_ASSUME_NONNULL_END