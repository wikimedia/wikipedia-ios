#import "WMFDisambiguationPagesViewController.h"
#import "WMFArticleFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

// Frameworks
#import "Wikipedia-Swift.h"

// View
#import <WMF/UIView+WMFDefaultNib.h>

// Fetcher
#import <WMF/WMFArticlePreviewFetcher.h>

// Model
#import <WMF/MWKArticle.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/MWKHistoryEntry.h>
#import <WMF/MWKDataStore.h>

@import WMF.MWKDataStore;
@import WMF.WMFArticlePreviewFetcher;

@interface WMFDisambiguationPagesViewController ()

@property (nonatomic, strong, readwrite) NSArray<NSURL *> *URLs;
@property (nonatomic, strong, readwrite) NSURL *siteURL;

@property (nonatomic, strong) WMFArticlePreviewFetcher *titlesSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) NSArray<MWKSearchResult *> *previewResults;
@property (nonatomic, assign) NSUInteger resultLimit;

@end

@implementation WMFDisambiguationPagesViewController

- (instancetype)initWithURLs:(NSArray *)URLs siteURL:(NSURL *)siteURL dataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.URLs = URLs;
        self.siteURL = siteURL;
        self.userDataStore = dataStore;
        self.titlesSearchFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetch];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(xButtonPressed)];
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Fetching

- (void)fetch {
    @weakify(self);
    [self.titlesSearchFetcher fetchArticlePreviewResultsForArticleURLs:self.URLs
                                                               siteURL:self.siteURL
                                                            completion:^(NSArray<MWKSearchResult *> *_Nonnull searchResults) {
                                                                @strongify(self);
                                                                if (!self) {
                                                                    return;
                                                                }
                                                                self.previewResults = searchResults;
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    [self.tableView reloadData];
                                                                });
                                                            }
                                                               failure:^(NSError *_Nonnull error){
                                                               }];
}

#pragma mark - DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.previewResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];
    
    NSURL *URL = [self urlAtIndexPath:indexPath];
    MWKSearchResult *searchResult = [self searchResultForIndexPath:indexPath];
    
    NSParameterAssert([URL.wmf_domain isEqual:self.siteURL.wmf_domain]);
    cell.titleText = URL.wmf_title;
    cell.descriptionText = [searchResult.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.siteURL.wmf_language];
    [cell setImageURL:searchResult.thumbnailURL];
    [cell applyTheme:self.theme];
    
    return cell;
}

- (MWKSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = self.previewResults[indexPath.row];
    return result;
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [self.siteURL wmf_URLWithTitle:[self searchResultForIndexPath:indexPath].displayTitle];
}

- (NSUInteger)titleCount {
    return [self.previewResults count];
}

- (nullable NSString *)displayTitle {
    return WMFLocalizedStringWithDefaultValue(@"page-similar-titles", nil, nil, @"Similar pages", @"Label for button that shows a list of similar titles (disambiguation) for the current page");
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
