@class MWKDataStore;
@class WMFThemeable;

@protocol WMFSettingsViewControllerDelegate

- (void)settingsViewControllerDidDisappear;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : UIViewController <WMFThemeable>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic) BOOL showCloseButton;

NS_ASSUME_NONNULL_END

@property (nullable, nonatomic, weak) id<WMFSettingsViewControllerDelegate> delegate;

@end
