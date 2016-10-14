#import <UIKit/UIKit.h>

@class MWKDataStore, WMFArticlePreviewDataStore;

@interface WMFSettingsViewController : UIViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store previewStore:(WMFArticlePreviewDataStore *)previewStore;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, strong, readonly) WMFArticlePreviewDataStore *previewStore;

@end
