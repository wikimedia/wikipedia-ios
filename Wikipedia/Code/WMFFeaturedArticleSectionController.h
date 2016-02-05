
#import "WMFBaseExploreSectionController.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeaturedArticleSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding>

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) NSDate* date;

- (instancetype)initWithSite:(MWKSite*)site
                        date:(NSDate*)date
               dataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END
