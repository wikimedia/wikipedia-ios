@class MWKDataStore;
@class WMFThemeable;

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)reloadVisibleCellOfType:(WMFSettingsMenuItemType)type;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@end
