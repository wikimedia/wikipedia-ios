@class MWKDataStore;
@class WMFThemeable;

@protocol WMFSettingsViewControllerDelegate

- (void)settingsViewControllerDidDisappear;

@end

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nullable, nonatomic, weak) id<WMFSettingsViewControllerDelegate> delegate;
@property (nonatomic) BOOL showCloseButton;

@end
