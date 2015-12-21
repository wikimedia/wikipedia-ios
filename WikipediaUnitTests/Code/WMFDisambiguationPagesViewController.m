#import "WMFDisambiguationPagesViewController.h"
#import "WMFArticlePreviewDataSource.h"
#import "MWKArticle.h"
#import "WMFArticlePreviewFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKDataStore.h"

@interface WMFDisambiguationPagesViewController ()

@property (nonatomic, strong, readwrite) MWKArticle* article;

@end

@implementation WMFDisambiguationPagesViewController

- (instancetype)initWithArticle:(MWKArticle*)article dataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.article              = article;
        self.dataStore            = dataStore;
        self.dataSource           = [[WMFArticlePreviewDataSource alloc] initWithTitles:self.article.disambiguationTitles site:self.article.site fetcher:[[WMFArticlePreviewFetcher alloc] init]];
        self.dataSource.tableView = self.tableView;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [((WMFArticlePreviewDataSource*)self.dataSource) fetch];
    @weakify(self);
    UIBarButtonItem* xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self.presentingViewController dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItem  = xButton;
    self.navigationItem.rightBarButtonItem = nil;
}

@end
