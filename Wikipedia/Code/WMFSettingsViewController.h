#import <UIKit/UIKit.h>

@class MWKDataStore, WMFArticleDataStore;

@interface WMFSettingsViewController : UIViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store previewStore:(WMFArticleDataStore *)previewStore;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, strong, readonly) WMFArticleDataStore *previewStore;

@end
