
#import "WMFHomeSectionController.h"

@class MWKSite, MWKSavedPageList;

@interface WMFMainPageSectionController : NSObject<WMFHomeSectionController>

@property (nonatomic, strong, readonly) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList;

@end
