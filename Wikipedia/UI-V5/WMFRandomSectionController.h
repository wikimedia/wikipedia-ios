
#import "WMFHomeSectionController.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomSectionController : NSObject<WMFHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

- (void)getNewRandomArticle;

@end

NS_ASSUME_NONNULL_END