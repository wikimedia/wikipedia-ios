@class MWKDataStore;
@class WMFThemeable;

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@end
