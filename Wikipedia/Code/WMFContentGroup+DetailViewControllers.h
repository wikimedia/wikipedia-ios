@import WMF;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (DetailViewControllers)

- (nullable UIViewController *)detailViewControllerWithDataStore:(MWKDataStore *)dataStore siteURL:(NSURL *)siteURL theme:(WMFTheme *)theme;

@end

NS_ASSUME_NONNULL_END
