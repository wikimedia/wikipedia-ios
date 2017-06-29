#import "WMFFeedContentDisplaying.h"
@import WMF.WMFContentGroup_CoreDataClass;

@class WMFNewsViewController;
@class MWKDataStore;
@class WMFFeedNewsStory;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (WMFContentManaging) <WMFFeedContentDisplaying>

- (nullable UIViewController *)detailViewControllerWithDataStore:(MWKDataStore *)dataStore siteURL:(NSURL *)siteURL;

@end

NS_ASSUME_NONNULL_END
