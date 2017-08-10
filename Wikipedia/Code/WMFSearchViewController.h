@import WMF.Swift;
@import UIKit;

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController <WMFAnalyticsContextProviding, WMFAnalyticsViewNameProviding, WMFThemeable>

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, copy) NSString *searchTerm;

- (void)performSearchWithCurrentSearchTerm;

+ (instancetype)searchViewControllerWithDataStore:(MWKDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
