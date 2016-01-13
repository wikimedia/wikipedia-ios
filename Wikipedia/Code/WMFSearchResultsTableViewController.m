
#import "WMFSearchResultsTableViewController.h"
#import "WMFArticleListTableViewCell+WMFSearch.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKSearchResult.h"
#import "MWKTitle.h"
#import "WMFSearchResults.h"
#import "MWKSearchRedirectMapping.h"
#import "NSString+Extras.h"

@implementation WMFSearchResultsTableViewController

@dynamic dataSource;

- (WMFSearchResults*)searchResults {
    return self.dataSource.searchResults;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];

    self.tableView.estimatedRowHeight = 60.0f;
}

- (void)setDataSource:(WMFSearchDataSource*)dataSource {
    dataSource.cellClass = [WMFArticleListTableViewCell class];

    @weakify(self);
    dataSource.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                                      MWKSearchResult* result,
                                      UITableView* tableView,
                                      NSIndexPath* indexPath) {
        @strongify(self);
        MWKTitle* title = [self.dataSource titleForIndexPath:indexPath];
        [cell setTitleText:title.text highlightingText:self.searchResults.searchTerm];
        cell.descriptionText = [self descriptionForSearchResult:result];
        [cell setImageURL:result.thumbnailURL];
    };

    [super setDataSource:dataSource];
}

- (MWKSearchRedirectMapping*)redirectMappingForResult:(MWKSearchResult*)result {
    return [self.searchResults.redirectMappings bk_match:^BOOL (MWKSearchRedirectMapping* obj) {
        if ([result.displayTitle isEqualToString:obj.redirectToTitle]) {
            return YES;
        }
        return NO;
    }];
}

- (NSString*)descriptionForSearchResult:(MWKSearchResult*)result {
    MWKSearchRedirectMapping* mapping = [self redirectMappingForResult:result];
    if (!mapping) {
        return result.wikidataDescription;
    }
    NSString* description = result.wikidataDescription ? [@"\n" stringByAppendingString : [result.wikidataDescription wmf_stringByCapitalizingFirstCharacter]] : @"";
    return [NSString stringWithFormat:@"Redirected from: %@%@", mapping.redirectFromTitle, description];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoSearchResults;
}

@end
