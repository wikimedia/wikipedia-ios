@import UIKit;
@class MWKDataStore;
@class WMFDonateDataController;
@class WMFProfileCoordinator;
@protocol NotificationsCenterPresentationDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : UIViewController <WMFThemeable, WMFPreferredLanguagesViewControllerDelegate>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store theme:(WMFTheme *)theme;

- (void)loadSections;

@property (nonatomic, strong) WMFTheme* theme;
@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nullable, nonatomic, strong) WMFProfileCoordinator *profileCoordinator;
@property (nonatomic, weak, nullable) id<NotificationsCenterPresentationDelegate> notificationsCenterPresentationDelegate;

@property (nullable, nonatomic, strong) UIView *topSafeAreaOverlayView;
@property (nullable, nonatomic, strong) NSLayoutConstraint *topSafeAreaOverlayHeightConstraint;

NS_ASSUME_NONNULL_END

@end
