#import <UIKit/UIKit.h>

@interface WMFSettingsViewController : UIViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

@property(nonatomic, strong, readonly) MWKDataStore *dataStore;

@end
