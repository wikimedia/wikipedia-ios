#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSite.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"

@interface WMFRandomArticleViewController ()

@property (nonatomic, strong) WMFRandomArticleFetcher* randomArticleFetcher;
@property (nonatomic, strong) MWKSite* site;
@end

@implementation WMFRandomArticleViewController

- (instancetype)initWithRandomArticleFetcher:(WMFRandomArticleFetcher*)randomArticleFetcher site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site                 = site;
        self.randomArticleFetcher = randomArticleFetcher;
    }
    return self;
}

- (void)fetchArticleIfNeeded {
    [self.randomArticleFetcher fetchRandomArticleWithSite:self.site failure:^(NSError* error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                  sticky:NO
                                   dismissPreviousAlerts:NO
                                             tapCallBack:NULL];
    } success:^(MWKSearchResult* searchResult) {
        self.articleTitle = [self.site titleWithString:searchResult.displayTitle];
        [super fetchArticleIfNeeded];
    }];
}

@end
