#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController<WMFAnalyticsLogging>

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

+ (instancetype)searchViewControllerWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END