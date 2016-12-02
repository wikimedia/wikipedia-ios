#import <Foundation/Foundation.h>
#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticleDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
