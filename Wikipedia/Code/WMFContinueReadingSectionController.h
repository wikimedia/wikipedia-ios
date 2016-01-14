#import "WMFExploreSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : NSObject <WMFArticleExploreSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@end
