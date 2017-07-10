#import "WMFFeedContentDisplaying.h"
@import WMF.WMFContentGroup_CoreDataClass;
@import WMF.Swift;

@class WMFNewsViewController;
@class MWKDataStore;
@class WMFFeedNewsStory;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (WMFContentManaging) <WMFFeedContentDisplaying>

- (nullable UIViewController *)detailViewControllerWithDataStore:(MWKDataStore *)dataStore siteURL:(NSURL *)siteURL theme:(WMFTheme *)theme;

@end

NS_ASSUME_NONNULL_END
