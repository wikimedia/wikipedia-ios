#import "WMFBaseExploreSectionController.h"

@class MWKDataStore;

@interface WMFContinueReadingSectionController
    : WMFBaseExploreSectionController <WMFExploreSectionController,
                                       WMFTitleProviding,
                                       WMFAnalyticsContentTypeProviding>

- (instancetype)initWithArticleURL:(NSURL *)articleURL
                         dataStore:(MWKDataStore *)dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                            items:(NSArray *)items NS_UNAVAILABLE;

@end
