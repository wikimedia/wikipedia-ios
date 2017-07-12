#import "WMFDisambiguationPagesViewController.h"
#import "WMFArticlePreviewDataSource.h"
#import "WMFArticleFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
@import WMF.MWKDataStore;
@import WMF.WMFArticlePreviewFetcher;

@interface WMFDisambiguationPagesViewController ()

@property (nonatomic, strong, readwrite) NSArray *URLs;
@property (nonatomic, strong, readwrite) NSURL *siteURL;

@end

@implementation WMFDisambiguationPagesViewController

- (instancetype)initWithURLs:(NSArray *)URLs siteURL:(NSURL*)siteURL  dataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.URLs = URLs;
        self.userDataStore = dataStore;
        self.dataSource =
            [[WMFArticlePreviewDataSource alloc] initWithArticleURLs:self.URLs
                                                             siteURL:siteURL
                                                           dataStore:dataStore
                                                             fetcher:[[WMFArticlePreviewFetcher alloc] init]];
        self.dataSource.tableView = self.tableView;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [((WMFArticlePreviewDataSource *)self.dataSource)fetch];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(xButtonPressed)];
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
