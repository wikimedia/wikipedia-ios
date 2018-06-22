@class MWKDataStore;
@class WMFThemeable;

@protocol WMFSettingsViewControllerDelegate

- (void)settingsViewControllerWasDismissed;

@end

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nullable, nonatomic, weak) id<WMFSettingsViewControllerDelegate> delegate;

@end
