
#import "WMFSearchDataSource.h"
#import "MWKTitle.h"
#import "WMFSearchResults.h"
#import "MWKSearchResult.h"
#import "MWKSearchRedirectMapping.h"
#import "NSString+Extras.h"
#import "WMFArticleListTableViewCell+WMFSearch.h"
#import "UIView+WMFDefaultNib.h"

@interface WMFSearchDataSource ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong, readwrite) WMFSearchResults* searchResults;

@end

@implementation WMFSearchDataSource

- (nonnull instancetype)initWithSearchSite:(MWKSite*)site searchResults:(WMFSearchResults*)searchResults {
    NSParameterAssert(site);
    NSParameterAssert(searchResults);
    self = [super initWithTarget:searchResults keyPath:WMF_SAFE_KEYPATH(searchResults, results)];
    if (self) {
        self.searchSite    = site;
        self.searchResults = searchResults;

        self.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                                    MWKSearchResult* result,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKTitle* title = [self titleForIndexPath:indexPath];
            [cell setTitleText:title.text highlightingText:self.searchResults.searchTerm];
            cell.descriptionText = [self descriptionForSearchResult:result];
            [cell setImageURL:result.thumbnailURL];
        };
    }
    return self;
}

- (NSString*)descriptionForSearchResult:(MWKSearchResult*)result {
    MWKSearchRedirectMapping* mapping = [self redirectMappingForResult:result];
    if (!mapping) {
        return result.wikidataDescription;
    }
    NSString* description = result.wikidataDescription ? [@"\n" stringByAppendingString : [result.wikidataDescription wmf_stringByCapitalizingFirstCharacter]] : @"";
    return [NSString stringWithFormat:@"Redirected from: %@%@", mapping.redirectFromTitle, description];
}

- (MWKSearchRedirectMapping*)redirectMappingForResult:(MWKSearchResult*)result {
    return [self.searchResults.redirectMappings bk_match:^BOOL (MWKSearchRedirectMapping* obj) {
        if ([result.displayTitle isEqualToString:obj.redirectToTitle]) {
            return YES;
        }
        return NO;
    }];
}

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
}

- (nullable NSString*)displayTitle {
    return self.searchResults.searchTerm;
}

- (NSArray*)titles {
    return [[self.searchResults results] bk_map:^id (MWKSearchResult* obj) {
        return [self.searchSite titleWithString:obj.displayTitle];
    }];
}

- (NSUInteger)titleCount {
    return [self.searchResults.results count];
}

- (MWKSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = self.searchResults.results[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [self.searchSite titleWithString:result.displayTitle];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)noResults {
    return (self.searchResults && [self.searchResults.results count] == 0);
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (CGFloat)estimatedItemHeight {
    return 60.f;
}

- (NSString*)analyticsName {
    return @"Search";
}


@end
