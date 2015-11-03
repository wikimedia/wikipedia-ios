
#import "WMFHomeSectionController.h"

@class MWKSite;

@interface WMFMainPageSectionController : NSObject<WMFHomeSectionController>

@property (nonatomic, strong, readonly) MWKSite* site;
- (instancetype)initWithSite:(MWKSite*)site;

@end
