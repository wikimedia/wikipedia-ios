
#import "WMFBaseExploreSectionController.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeaturedArticleSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding, WMFAnalyticsContentTypeProviding>

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) NSDate* date;

- (instancetype)initWithSite:(MWKSite*)site
                        date:(NSDate*)date
                   dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore items:(NSArray*)items NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
