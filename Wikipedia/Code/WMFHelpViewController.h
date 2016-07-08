
#import "WMFArticleViewController.h"

@class MWKDataStore;
@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFHelpViewController : WMFArticleViewController

- (instancetype)initWithArticleTitle:(nullable MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END