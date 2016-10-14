#import "WMFArticleViewController.h"

@class MWKDataStore, WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFHelpViewController : WMFArticleViewController

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticlePreviewDataStore *)previewStore;

@end

NS_ASSUME_NONNULL_END
