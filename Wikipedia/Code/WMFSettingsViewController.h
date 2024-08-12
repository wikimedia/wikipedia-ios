#import "WMFViewController.h"
@class MWKDataStore;
@class WMFDonateDataController;
@protocol NotificationsCenterPresentationDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : WMFViewController <WMFPreferredLanguagesViewControllerDelegate>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;
- (void)configureBarButtonItems;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, weak, nullable) id<NotificationsCenterPresentationDelegate> notificationsCenterPresentationDelegate;

NS_ASSUME_NONNULL_END

@end
