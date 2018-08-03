@class MWKDataStore;
@class WMFThemeable;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic) BOOL showCloseButton;

NS_ASSUME_NONNULL_END

@end
