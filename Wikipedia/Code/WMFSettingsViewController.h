#import "WMFViewController.h"
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSettingsViewController : WMFViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

- (void)loadSections;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

NS_ASSUME_NONNULL_END

@end
