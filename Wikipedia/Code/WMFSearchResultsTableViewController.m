#import "WMFSearchResultsTableViewController.h"
#import "WMFArticleListTableViewCell+WMFSearch.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKSearchResult.h"
#import "WMFSearchResults.h"
#import "MWKSearchRedirectMapping.h"
#import "NSString+WMFExtras.h"

@implementation WMFSearchResultsTableViewController

@dynamic dataSource;

- (WMFSearchResults *)searchResults {
    return self.dataSource.searchResults;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];

    self.tableView.estimatedRowHeight = 60.0f;

    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      @strongify(self);
                                                      [self.tableView reloadData];
                                                  }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDataSource:(WMFSearchDataSource *)dataSource {
    if (dataSource) {
        dataSource.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        dataSource.cellConfigureBlock = ^(WMFArticleListTableViewCell *cell,
                                          MWKSearchResult *result,
                                          UITableView *tableView,
                                          NSIndexPath *indexPath) {
            @strongify(self);
            NSURL *articleURL = [self.dataSource urlForIndexPath:indexPath];
            [cell wmf_setTitleText:articleURL.wmf_title highlightingText:self.searchResults.searchTerm];
            cell.titleLabel.accessibilityLanguage = self.dataSource.searchSiteURL.wmf_language;
            cell.descriptionText = [self descriptionForSearchResult:result];
            // TODO: In "Redirected from: %1$@", "%1$@" can be in any language; need to handle that too, currently (continuing) doing nothing for such cases
            cell.descriptionLabel.accessibilityLanguage = [self redirectMappingForResult:result] == nil ? self.dataSource.searchSiteURL.wmf_language : nil;
            [cell setImageURL:result.thumbnailURL failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
        };
    }

    [super setDataSource:dataSource];
}

- (MWKSearchRedirectMapping *)redirectMappingForResult:(MWKSearchResult *)result {
    return [self.searchResults.redirectMappings wmf_match:^BOOL(MWKSearchRedirectMapping *obj) {
        if ([result.displayTitle isEqualToString:obj.redirectToTitle]) {
            return YES;
        }
        return NO;
    }];
}

- (NSString *)descriptionForSearchResult:(MWKSearchResult *)result {
    MWKSearchRedirectMapping *mapping = [self redirectMappingForResult:result];
    if (!mapping) {
        return result.wikidataDescription;
    }

    NSString *redirectedResultMessage = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"search-result-redirected-from", nil, nil, @"Redirected from: %1$@", @"Text for search result letting user know if a result is a redirect from another article. Parameters:\n* %1$@ - article title the current search result redirected from"), mapping.redirectFromTitle];

    if (!result.wikidataDescription) {
        return redirectedResultMessage;
    } else {
        return [NSString stringWithFormat:@"%@\n%@", redirectedResultMessage, [result.wikidataDescription wmf_stringByCapitalizingFirstCharacter]];
    }
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNone; //Is controlled by the search VC
}

- (NSString *)analyticsContext {
    return @"Search";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

- (BOOL)isDisplayingResultsForSearchTerm:(NSString *)searchTerm fromSiteURL:(NSURL *)siteURL {
    return (
        self.dataSource.searchResults.results.count > 0 &&                     // we have results already
        [self.dataSource.searchSiteURL wmf_isEqualToIgnoringScheme:siteURL] && // results are from same search site url
        [self.dataSource.searchResults.searchTerm isEqualToString:searchTerm]  // results are for same search term
        );
}

@end
