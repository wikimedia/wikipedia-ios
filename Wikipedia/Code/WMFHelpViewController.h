#import "WMFArticleViewController.h"

@class MWKDataStore, WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFHelpViewController : WMFArticleViewController

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore;

@end

NS_ASSUME_NONNULL_END
