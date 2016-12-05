#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKDataStore, WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController <WMFAnalyticsContextProviding, WMFAnalyticsViewNameProviding>

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, strong, readonly) WMFArticleDataStore *previewStore;

+ (instancetype)searchViewControllerWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore;

- (void)setSearchTerm:(NSString *)searchTerm;

@end

NS_ASSUME_NONNULL_END
