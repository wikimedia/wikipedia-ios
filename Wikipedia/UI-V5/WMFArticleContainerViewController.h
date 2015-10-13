@import UIKit;
#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class MWKTitle;
@class MWKHistoryEntry;

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controller responsible for displaying article content.
 */
@interface WMFArticleContainerViewController : UIViewController
    <WMFAnalyticsLogging>

- (instancetype)initWithArticleTitle:(MWKTitle*)title dataStore:(MWKDataStore *)dataStore;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

@end

NS_ASSUME_NONNULL_END
