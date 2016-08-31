
#import "WMFFeedSource.h"

@class WMFFeedDataStore;
@class MWKDataStore;
@class WMFArticlePreviewDataStore;

@interface WMFMoreLikeFeedSource : NSObject<WMFFeedSource>

@property (readonly, nonatomic, strong) WMFFeedDataStore *feedStore;
@property (readonly, nonatomic, strong) MWKDataStore *userDataStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithFeedDataStore:(WMFFeedDataStore*)feedStore userDataStore:(MWKDataStore*)userDataStore articlePreviewDataStore:(WMFArticlePreviewDataStore*)previewStore;

- (instancetype)init NS_UNAVAILABLE;

@end
