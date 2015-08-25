
#import "WMFHomeSectionController.h"

@class WMFRelatedSearchFetcher;
@class MWKTitle;

@interface WMFRelatedSectionController : NSObject <WMFHomeSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher;

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) WMFRelatedSearchFetcher* relatedSearchFetcher;

@end
