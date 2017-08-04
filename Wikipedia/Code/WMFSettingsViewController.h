@class MWKDataStore;
@class WMFThemeable;

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@end
