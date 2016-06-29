#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSite.h"

@interface WMFRandomArticleViewController ()

@property (nonatomic, strong) WMFRandomArticleFetcher* randomArticleFetcher;
@property (nonatomic, strong) MWKSite *site;
@end

@implementation WMFRandomArticleViewController

- (instancetype)initWithRandomArticleFetcher:(WMFRandomArticleFetcher*)randomArticleFetcher site:(MWKSite *)site dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site = site;
        self.randomArticleFetcher = randomArticleFetcher;
    }
    return self;
}

@end
