#import "WMFBaseExploreSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : WMFBaseExploreSectionController <WMFTitleProviding>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@end
