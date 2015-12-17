#import "WMFDisambiguationPagesViewController.h"
#import "WMFDisambiguationTitlesDataSource.h"
#import "MWKArticle.h"
#import "WMFTitlesSearchFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "WMFTitlesSearchFetcher.h"
#import "MWKDataStore.h"

@interface WMFDisambiguationPagesViewController ()

@property (nonatomic, strong, readwrite) MWKArticle* article;

@end

@implementation WMFDisambiguationPagesViewController

- (instancetype)initWithArticle:(MWKArticle*)article dataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.article = article;
        self.dataStore = dataStore;
        self.dataSource = [[WMFDisambiguationTitlesDataSource alloc] initWithTitles:self.article.disambiguationTitles site:self.article.site fetcher:[[WMFTitlesSearchFetcher alloc] init]];
        self.dataSource.tableView = self.tableView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    @weakify(self);
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self.presentingViewController dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItem = xButton;
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)viewWillAppear:(BOOL)animated {
//TODO: cancel fetch on viewwilldisappear
    [super viewWillAppear:animated];
    [((WMFDisambiguationTitlesDataSource*)self.dataSource) fetch];
}

@end
