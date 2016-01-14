
#import "WMFExploreSectionController.h"

@class MWKSite, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFRandomSectionIdentifier;

@interface WMFRandomSectionController : NSObject
    <WMFArticleExploreSectionController, WMFFetchingExploreSectionController>

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

@end

NS_ASSUME_NONNULL_END