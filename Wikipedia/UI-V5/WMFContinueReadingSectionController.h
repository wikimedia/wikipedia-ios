#import "WMFHomeSectionController.h"

@class MWKTitle, MWKDataStore;

@interface WMFContinueReadingSectionController : NSObject <WMFHomeSectionController>

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore
                            delegate:(id<WMFHomeSectionControllerDelegate>)delegate;

@end
