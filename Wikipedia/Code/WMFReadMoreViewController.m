#import "WMFReadMoreViewController.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"
#import "WMFRelatedTitleListDataSource.h"
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"

@interface WMFReadMoreViewController () <WMFAnalyticsContentTypeProviding>

@property (nonatomic, strong, readwrite) NSURL *articleURL;
@property (nonatomic, strong) WMFRelatedTitleListDataSource *dataSource;

@end

@implementation WMFReadMoreViewController

@dynamic dataSource;

- (instancetype)initWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url.wmf_title);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.articleURL = url;
        self.dataStore = dataStore;
        self.dataSource = [[WMFRelatedTitleListDataSource alloc] initWithURL:self.articleURL dataStore:self.dataStore resultLimit:3];
        self.dataSource.cellClass = [WMFArticlePreviewTableViewCell class];

        @weakify(self);
        self.dataSource.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell *cell,
                                               MWKSearchResult *searchResult,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);
            NSURL *url = [self.articleURL wmf_URLWithTitle:searchResult.displayTitle];
            [cell setSaveableURL:url savedPageList:self.savedPageList];
            cell.titleText = searchResult.displayTitle;
            cell.descriptionText = searchResult.wikidataDescription;
            cell.snippetText = searchResult.extract;
            [cell setImageURL:searchResult.thumbnailURL];
            cell.saveButtonController.analyticsContext = self;
            cell.saveButtonController.analyticsContentType = self;
        };
    }
    return self;
}

- (MWKSavedPageList *)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (AnyPromise *)fetchIfNeeded {
    if ([self hasResults]) {
        return [AnyPromise promiseWithValue:self.dataSource.relatedSearchResults];
    } else {
        return [self.dataSource fetch];
    }
}

- (BOOL)hasResults {
    return [self.dataSource.relatedSearchResults.results count] > 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    [self.tableView reloadData];
}

- (NSString *)analyticsContext {
    return @"Reader";
}

- (NSString *)analyticsContentType {
    return @"Read More";
}

@end
