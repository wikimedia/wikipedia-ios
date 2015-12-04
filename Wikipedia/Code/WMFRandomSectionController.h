
#import "WMFHomeSectionController.h"

@class MWKSite, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomSectionController : NSObject<WMFArticleHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

- (void)getNewRandomArticle;

@end

NS_ASSUME_NONNULL_END