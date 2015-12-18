@import UIKit;
#import "MWKHistoryEntry.h"

@class MWKDataStore;
@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controller responsible for displaying article content.
 */
@interface WMFArticleContainerViewController : UIViewController

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore
                     discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, assign, readonly) MWKHistoryDiscoveryMethod discoveryMethod;

@end

NS_ASSUME_NONNULL_END
