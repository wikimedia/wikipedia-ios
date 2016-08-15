#import "WMFBaseExploreSectionController.h"

@interface WMFPictureOfTheDaySectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFAnalyticsContentTypeProviding>

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore date:(NSDate*)date;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore items:(NSArray*)items NS_UNAVAILABLE;

@end
