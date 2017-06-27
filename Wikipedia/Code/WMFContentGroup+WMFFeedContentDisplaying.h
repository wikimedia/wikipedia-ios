#import "WMFFeedContentDisplaying.h"

@class WMFNewsViewController;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (WMFContentManaging) <WMFFeedContentDisplaying>

- (nullable UIViewController *)detailViewControllerWithDataStore:(MWKDataStore *)dataStore siteURL:(NSURL *)siteURL;
+ (nullable WMFNewsViewController *)inTheNewsViewControllerForStories:(NSArray<WMFFeedNewsStory *> *)stories dataStore:(MWKDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
