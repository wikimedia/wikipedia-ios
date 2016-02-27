#import "WMFBaseExploreSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : WMFBaseExploreSectionController <WMFExploreSectionController, WMFTitleProviding, WMFAnalyticsContentTypeProviding>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore items:(NSArray*)items NS_UNAVAILABLE;

@end
