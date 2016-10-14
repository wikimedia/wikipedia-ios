#import "WMFTimerContentSource.h"
#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticlePreviewDataStore;

@interface WMFMainPageContentSource : WMFTimerContentSource <WMFContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;
@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end
