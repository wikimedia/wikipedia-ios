
#import "WMFBaseExploreSectionController.h"

@class MWKSite, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFMainPageSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding>

@property (nonatomic, strong, readonly) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList;

@end

NS_ASSUME_NONNULL_END
