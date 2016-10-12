#import "WMFArticleViewController.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFHelpViewController : WMFArticleViewController

- (instancetype)initWithArticleURL:(NSURL *)url
                         dataStore:(MWKDataStore *)dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
