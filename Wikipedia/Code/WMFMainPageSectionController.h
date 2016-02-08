
#import "WMFBaseExploreSectionController.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFMainPageSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding>

@property (nonatomic, strong, readonly) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;


@end

NS_ASSUME_NONNULL_END
