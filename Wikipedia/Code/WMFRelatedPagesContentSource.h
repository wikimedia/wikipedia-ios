#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class MWKDataStore;
@class WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedPagesContentSource : NSObject <WMFContentSource, WMFAutoUpdatingContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) MWKDataStore *userDataStore;
@property (readonly, nonatomic, strong) WMFArticleDataStore *previewStore;

- (instancetype)initWithContentGroupDataStore:(WMFContentGroupDataStore *)contentStore userDataStore:(MWKDataStore *)userDataStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
