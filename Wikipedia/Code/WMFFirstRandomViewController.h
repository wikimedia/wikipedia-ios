#import <UIKit/UIKit.h>

@class MWKDataStore;

//This VC is a placeholder to load the first random article

NS_ASSUME_NONNULL_BEGIN

@interface WMFFirstRandomViewController : UIViewController

@property (nonatomic, strong, nonnull) NSURL *siteURL;
@property (nonatomic, strong, nonnull) MWKDataStore *dataStore;
#if WMF_TWEAKS_ENABLED
@property (nonatomic, getter=isPermaRandomMode) BOOL permaRandomMode;
#endif

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL *)siteURL dataStore:(nonnull MWKDataStore *)dataStore NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
