
#import "WMFHomeSectionController.h"

@class WMFRelatedSearchFetcher;
@class MWKTitle;
@class MWKSavedPageList;

@interface WMFRelatedSectionController : NSObject <WMFArticleHomeSectionController, WMFFetchingHomeSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                       savedPageList:(MWKSavedPageList*)savedPageList;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                       savedPageList:(MWKSavedPageList*)savedPageList
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) WMFRelatedSearchFetcher* relatedSearchFetcher;

@end
