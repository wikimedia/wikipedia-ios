#import "WMFBaseExploreSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : WMFBaseExploreSectionController <WMFExploreSectionController, WMFTitleProviding, WMFAnalyticsContentTypeProviding>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@end
