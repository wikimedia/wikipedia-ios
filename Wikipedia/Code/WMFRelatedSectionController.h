
#import "WMFExploreSectionController.h"

@class WMFRelatedSearchFetcher;
@class MWKTitle;
@class WMFRelatedSectionBlackList;
@class MWKDataStore;

@interface WMFRelatedSectionController : NSObject <WMFArticleExploreSectionController, WMFFetchingExploreSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           blackList:(WMFRelatedSectionBlackList*)blackList
                           dataStore:(MWKDataStore*)dataStore
                              tabBar:(UITabBar*)tabBar;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           blackList:(WMFRelatedSectionBlackList*)blackList
                           dataStore:(MWKDataStore*)dataStore
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher
                              tabBar:(UITabBar*)tabBar NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) WMFRelatedSearchFetcher* relatedSearchFetcher;
@property (nonatomic, strong, readonly) UITabBar* tabBar;

@end
