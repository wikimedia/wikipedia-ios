#import "WMFArticleViewController.h"

@class WMFRandomArticleFetcher;
@class MWKSite;
@class MWKDataStore;

@interface WMFRandomArticleViewController : WMFArticleViewController

- (instancetype)initWithArticleTitle:(MWKTitle*)title randomArticleFetcher:(WMFRandomArticleFetcher*)randomArticleFetcher site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;


@end
