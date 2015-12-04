#import "WMFHomeSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : NSObject <WMFArticleHomeSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore;

@end
