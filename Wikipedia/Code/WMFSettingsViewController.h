#import "WMFViewController.h"
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : WMFViewController <WMFPreferredLanguagesViewControllerDelegate>

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store andPushNotificationsController:(WMFPushNotificationsController *)pushNotificationsController;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;


NS_ASSUME_NONNULL_END

@end
