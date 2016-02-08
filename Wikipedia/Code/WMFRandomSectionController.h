
#import "WMFBaseExploreSectionController.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFRandomSectionIdentifier;

@interface WMFRandomSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding, WMFHeaderActionProviding>

- (instancetype)initWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;


@property (nonatomic, strong, readonly) MWKSite* searchSite;

@end

NS_ASSUME_NONNULL_END