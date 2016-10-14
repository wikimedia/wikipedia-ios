#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKDataStore, WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController <WMFAnalyticsContextProviding, WMFAnalyticsViewNameProviding>

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, strong, readonly) WMFArticlePreviewDataStore *previewStore;

+ (instancetype)searchViewControllerWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticlePreviewDataStore *)previewStore;

- (void)setSearchTerm:(NSString *)searchTerm;

@end

NS_ASSUME_NONNULL_END
