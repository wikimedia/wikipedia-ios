#import "WMFBaseExploreSectionController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMainPageSectionController : WMFBaseExploreSectionController <WMFExploreSectionController, WMFTitleProviding, WMFAnalyticsContentTypeProviding>

@property (nonatomic, strong, readonly) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore items:(NSArray *)items NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
