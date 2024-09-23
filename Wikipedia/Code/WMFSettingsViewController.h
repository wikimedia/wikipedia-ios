@import UIKit;
@class MWKDataStore;
@class WMFDonateDataController;
@protocol NotificationsCenterPresentationDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : UIViewController <WMFThemeable, WMFPreferredLanguagesViewControllerDelegate>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store theme:(WMFTheme *)theme;

- (void)loadSections;
- (void)configureBarButtonItems;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, weak, nullable) id<NotificationsCenterPresentationDelegate> notificationsCenterPresentationDelegate;

NS_ASSUME_NONNULL_END

@end
