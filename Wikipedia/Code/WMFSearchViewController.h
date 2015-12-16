#import <UIKit/UIKit.h>
#import "WMFArticleSelectionDelegate.h"
#import "WMFAnalyticsLogging.h"

@class MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchViewController : UIViewController<WMFAnalyticsLogging>

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

/**
 *  Informed when the receiver selects a search result.
 *
 *  The @c sender argument in the delegate callback is set to the receiver.
 */
@property (nonatomic, weak, nullable) id<WMFArticleSelectionDelegate> searchResultDelegate;

+ (instancetype)searchViewControllerWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END