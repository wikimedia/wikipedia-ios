#import "WMFSearchResultsTableViewController.h"
#import "WMFSearchResults.h"
#import "MWKSearchRedirectMapping.h"
#import "Wikipedia-Swift.h"
@import WMF;

@implementation WMFSearchResultsTableViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];

    [cell applyTheme:self.theme];
    NSURL *articleURL = [self urlAtIndexPath:indexPath];
    NSString *language = self.searchSiteURL.wmf_language;
    NSLocale *locale = [NSLocale wmf_localeForWikipediaLanguage:language];
    MWKSearchResult *result = [self searchResultForIndexPath:indexPath];

    [cell setTitleText:articleURL.wmf_title highlightingText:self.searchResults.searchTerm locale:locale];
    cell.articleCell.titleLabel.accessibilityLanguage = language;
    cell.descriptionText = [self descriptionForSearchResult:result];
    // TODO: In "Redirected from: %1$@", "%1$@" can be in any language; need to handle that too, currently (continuing) doing nothing for such cases
    cell.articleCell.descriptionLabel.accessibilityLanguage = [self redirectMappingForResult:result] == nil ? language : nil;
    [cell setImageURL:result.thumbnailURL];

    return cell;
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = [self searchResultForIndexPath:indexPath];
    return [self.searchSiteURL wmf_URLWithTitle:result.displayTitle];
}

- (MWKSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = self.searchResults.results[indexPath.row];
    return result;
}

- (BOOL)noResults {
    return (self.searchResults && [self.searchResults.results count] == 0);
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
        return [result.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.searchSiteURL.wmf_language];
    }

    NSString *redirectedResultMessage = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"search-result-redirected-from", nil, nil, @"Redirected from: %1$@", @"Text for search result letting user know if a result is a redirect from another article. Parameters:\n* %1$@ - article title the current search result redirected from"), mapping.redirectFromTitle];

    if (!result.wikidataDescription) {
        return redirectedResultMessage;
    } else {
        return [NSString stringWithFormat:@"%@\n%@", redirectedResultMessage, [result.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.searchSiteURL.wmf_language]];
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
        self.searchResults.results.count > 0 && // we have results already
        [self.searchSiteURL wmf_isEqualToIgnoringScheme:siteURL] && // results are from same search site url
        [self.searchResults.searchTerm isEqualToString:searchTerm] // results are for same search term
    );
}

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewRowActions *rowActions = [[WMFArticleListTableViewRowActions alloc] init];
    [rowActions applyTheme:self.theme];

    NSURL *url = [self urlAtIndexPath:indexPath];
    MWKSavedPageList *savedPageList = [self.userDataStore savedPageList];

    BOOL isItemSaved = [[self savedPageList] isSaved:[self urlAtIndexPath:indexPath]];

    UITableViewRowAction *share = [rowActions actionFor:ArticleListTableViewRowActionTypeShare
                                                     at:indexPath
                                                     in:tableView
                                                perform:^(NSIndexPath *indexPath) {
                                                    [self shareArticle:url];
                                                }];

    NSMutableArray *actions = [[NSMutableArray alloc] initWithObjects:share, nil];

    if (isItemSaved) {
        UITableViewRowAction *unsave = [rowActions actionFor:ArticleListTableViewRowActionTypeUnsave
                                                          at:indexPath
                                                          in:tableView
                                                     perform:^(NSIndexPath *indexPath) {
                                                         [savedPageList removeEntryWithURL:url];
                                                     }];
        [actions addObject:unsave];
    } else {
        UITableViewRowAction *save = [rowActions actionFor:ArticleListTableViewRowActionTypeSave
                                                        at:indexPath
                                                        in:tableView
                                                   perform:^(NSIndexPath *indexPath) {
                                                       [savedPageList addSavedPageWithURL:url];
                                                   }];
        [actions addObject:save];
    }

    return actions;
}

@end
