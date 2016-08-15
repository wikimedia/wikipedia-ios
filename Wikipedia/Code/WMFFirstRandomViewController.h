#import <UIKit/UIKit.h>

@class MWKDataStore;

//This VC is a placeholder to load the first random article

@interface WMFFirstRandomViewController: UIViewController

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL*)siteURL dataStore:(nonnull MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;

@end
