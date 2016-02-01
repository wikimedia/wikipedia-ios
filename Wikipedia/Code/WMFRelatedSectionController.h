
#import "WMFBaseExploreSectionController.h"

@class WMFRelatedSearchFetcher;
@class MWKTitle;
@class WMFRelatedSectionBlackList;
@class MWKDataStore;

@interface WMFRelatedSectionController : WMFBaseExploreSectionController <WMFExploreSectionController, WMFTitleProviding, WMFHeaderMenuProviding, WMFMoreFooterProviding>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           blackList:(WMFRelatedSectionBlackList*)blackList
                           dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           blackList:(WMFRelatedSectionBlackList*)blackList
                           dataStore:(MWKDataStore*)dataStore
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) WMFRelatedSearchFetcher* relatedSearchFetcher;

@end
