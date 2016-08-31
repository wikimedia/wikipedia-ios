
#import "WMFTimerFeedSource.h"

@class WMFFeedDataStore;
@class WMFArticlePreviewDataStore;

@interface WMFMainPageFeedSource : WMFTimerFeedSource

@property (readonly, nonatomic, strong) NSURL *siteURL;
@property (readonly, nonatomic, strong) WMFFeedDataStore *feedStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL*)siteURL feedDataStore:(WMFFeedDataStore*)feedStore articlePreviewDataStore:(WMFArticlePreviewDataStore*)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end
