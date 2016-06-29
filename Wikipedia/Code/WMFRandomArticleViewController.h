#import "WMFArticleViewController.h"

@class WMFRandomArticleFetcher;
@class MWKSite;
@class MWKDataStore;

@interface WMFRandomArticleViewController : WMFArticleViewController

- (instancetype)initWithRandomArticleFetcher:(WMFRandomArticleFetcher*)randomArticleFetcher site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end
