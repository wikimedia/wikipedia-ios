#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticleDataStore;

@interface WMFNearbyContentSource : NSObject <WMFContentSource, WMFAutoUpdatingContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;
@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticleDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end
