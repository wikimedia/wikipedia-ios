#import "WMFDisambiguationPagesViewController.h"
#import "WMFArticlePreviewDataSource.h"
#import "MWKArticle.h"
#import "WMFArticleFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "WMFArticleFetcher.h"
#import "MWKDataStore.h"

@interface WMFDisambiguationPagesViewController ()

@property (nonatomic, strong, readwrite) MWKArticle *article;

@end

@implementation WMFDisambiguationPagesViewController

- (instancetype)initWithArticle:(MWKArticle *)article dataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.article = article;
        self.userDataStore = dataStore;
        self.dataSource =
            [[WMFArticlePreviewDataSource alloc] initWithArticleURLs:self.article.disambiguationURLs
                                                             siteURL:self.article.url
                                                           dataStore:dataStore
                                                             fetcher:[[WMFArticlePreviewFetcher alloc] init]];
        self.dataSource.tableView = self.tableView;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [((WMFArticlePreviewDataSource *)self.dataSource)fetch];
    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(xButtonPressed)];
    self.navigationItem.leftBarButtonItem = xButton;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)xButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (NSString *)analyticsContext {
    return @"Disambiguation";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

- (void)updateEmptyAndDeleteState {
    //Empty override to prevent nil'ing of left bar button item (the x button) caused by the default implementation
}

@end
