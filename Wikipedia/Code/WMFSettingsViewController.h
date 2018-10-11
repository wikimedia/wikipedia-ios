@class MWKDataStore;
@class WMFThemeable;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : WMFViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

NS_ASSUME_NONNULL_END

@end
