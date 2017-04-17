#import <UIKit/UIKit.h>

@class MWKDataStore;

@interface WMFSettingsViewController : UIViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@end
