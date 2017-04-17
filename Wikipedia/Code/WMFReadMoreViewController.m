#import "WMFReadMoreViewController.h"
#import "MWKDataStore.h"
#import "WMFRelatedSearchFetcher.h"
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"

@interface WMFReadMoreViewController () <WMFAnalyticsContentTypeProviding>

@property (nonatomic, strong, readwrite) NSURL *articleURL;

@property (nonatomic, strong) WMFRelatedSearchFetcher *relatedSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) WMFRelatedSearchResults *relatedSearchResults;

@end

@implementation WMFReadMoreViewController

- (instancetype)initWithURL:(NSURL *)url userStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(url.wmf_title);
    NSParameterAssert(userDataStore);
    self = [super init];
    if (self) {
        self.articleURL = url;
        self.userDataStore = userDataStore;
        self.relatedSearchFetcher = [[WMFRelatedSearchFetcher alloc] init];
    }
    return self;
}

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticlePreviewTableViewCell estimatedRowHeight];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.relatedSearchResults.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticlePreviewTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticlePreviewTableViewCell identifier] forIndexPath:indexPath];

    MWKSearchResult *preview = [self.relatedSearchResults.results objectAtIndex:indexPath.row];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    cell.snippetText = preview.extract;
    [cell setImageURL:preview.thumbnailURL];
    cell.saveButtonController.analyticsContext = [self analyticsContext];
    cell.saveButtonController.analyticsContentType = [self analyticsContentType];
    [cell setSaveableURL:[self.relatedSearchResults urlForResult:preview] savedPageList:self.userDataStore.savedPageList];

    return cell;
}

- (void)fetchIfNeededWithCompletionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                            failureBlock:(void (^)(NSError *error))failure {
    if ([self hasResults]) {
        if (completion) {
            completion(self.relatedSearchResults);
        }
    } else {
        @weakify(self);
        [self.relatedSearchFetcher fetchArticlesRelatedArticleWithURL:self.articleURL
            resultLimit:3
            completionBlock:^(WMFRelatedSearchResults *_Nonnull results) {
                @strongify(self);
                self.relatedSearchResults = results;
                if (completion) {
                    completion(results);
                }

            }
            failureBlock:^(NSError *_Nonnull error) {
                if (failure) {
                    failure(error);
                }
            }];
    }
}

- (BOOL)hasResults {
    return [self.relatedSearchResults.results count] > 0;
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [self.relatedSearchResults urlForResult:self.relatedSearchResults.results[indexPath.row]];
}

- (NSString *)analyticsContext {
    return @"Article";
}

- (NSString *)analyticsContentType {
    return @"Read More";
}

@end
