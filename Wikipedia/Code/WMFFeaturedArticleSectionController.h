
#import "WMFHomeSectionController.h"

@class MWKSite, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeaturedArticleSectionController : NSObject
    <WMFArticleHomeSectionController, WMFFetchingHomeSectionController>

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) NSDate* date;

- (instancetype)initWithSite:(MWKSite*)site
                        date:(NSDate*)date
               savedPageList:(MWKSavedPageList*)savedPageList;

@end

NS_ASSUME_NONNULL_END
