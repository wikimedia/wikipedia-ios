#import <UIKit/UIKit.h>

@class MWKDataStore, WMFArticleDataStore;

//This VC is a placeholder to load the first random article

NS_ASSUME_NONNULL_BEGIN

@interface WMFFirstRandomViewController : UIViewController

@property (nonatomic, strong, nonnull) NSURL *siteURL;
@property (nonatomic, strong, nonnull) MWKDataStore *dataStore;
@property (nonatomic, strong, nonnull) WMFArticleDataStore *previewStore;

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL *)siteURL dataStore:(nonnull MWKDataStore *)dataStore previewStore:(nonnull WMFArticleDataStore *)previewStore NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
