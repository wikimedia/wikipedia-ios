
#import "WMFExploreSectionController.h"

@class WMFRelatedSearchFetcher;
@class MWKTitle;
@class MWKDataStore;

@interface WMFRelatedSectionController : NSObject <WMFArticleExploreSectionController, WMFFetchingExploreSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) WMFRelatedSearchFetcher* relatedSearchFetcher;

@end
