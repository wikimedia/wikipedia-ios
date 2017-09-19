import UIKit
import WMF

@objc(WMFSearchResultsViewController)
class SearchResultsViewController: ArticleCollectionViewController {
    @objc var searchResults: WMFSearchResults? = nil {
        didSet {
            collectionView?.reloadData()
        }
    }
    @objc var searchSiteURL: URL? = nil
    
    
    @objc(isDisplayingResultsForSearchTerm:fromSiteURL:)
    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        return false
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return searchResults?.results?[indexPath.item].articleURL(forSiteURL: searchSiteURL)
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchArticle(with: articleURL)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults?.results?.count ?? 0
    }
    func redirectMappingForSearchResult(_ result: MWKSearchResult) -> MWKSearchRedirectMapping? {
        return searchResults?.redirectMappings?.filter({ (mapping) -> Bool in
            return result.displayTitle == mapping.redirectToTitle
        }).first
    }
    func descriptionForSearchResult(_ result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = (result.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: searchSiteURL?.wmf_language)
        let mapping = redirectMappingForSearchResult(result)
        guard let redirectFromTitle = mapping?.redirectFromTitle else {
            return capitalizedWikidataDescription
        }
        
        let redirectFormat = WMFLocalizedString("search-result-redirected-from", value: "Redirected from: %1$@", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters:\n* %1$@ - article title the current search result redirected from")
        let redirectMessage = String.localizedStringWithFormat(redirectFormat, redirectFromTitle)
        
        guard let description = capitalizedWikidataDescription else {
            return redirectMessage
        }
        
        return String.localizedStringWithFormat("%@\n%@", redirectMessage, description)
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let result = searchResults?.results?[indexPath.item],
            let articleURL = articleURL(at: indexPath),
            let language = searchSiteURL?.wmf_language else {
            return
        }
        let locale = NSLocale.wmf_locale(for: language)
        cell.configureForCompactList(at: indexPath)
        cell.set(titleTextToAttribute: articleURL.wmf_title, highlightingText: searchResults?.searchTerm, locale: locale)
        cell.titleLabel.accessibilityLanguage = language
        cell.descriptionLabel.text = descriptionForSearchResult(result)
        cell.descriptionLabel.accessibilityLanguage = language
        cell.imageURL = result.thumbnailURL
        cell.apply(theme: theme)
    }
}


//                
//                - (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
//                    MWKSearchResult *result = [self searchResultForIndexPath:indexPath];
//                    return [self.searchSiteURL wmf_URLWithTitle:result.displayTitle];
//                    }
//                    
//                    - (MWKSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
//                        MWKSearchResult *result = self.searchResults.results[indexPath.row];
//                        return result;
//                        }
//                        
//                        - (BOOL)noResults {
//                            return (self.searchResults && [self.searchResults.results count] == 0);
//                            }
//                            
//                            - (MWKSearchRedirectMapping *)redirectMappingForResult:(MWKSearchResult *)result {
//                                return [self.searchResults.redirectMappings wmf_match:^BOOL(MWKSearchRedirectMapping *obj) {
//                                    if ([result.displayTitle isEqualToString:obj.redirectToTitle]) {
//                                    return YES;
//                                    }
//                                    return NO;
//                                    }];
//                                }
//                                
//                                - (NSString *)descriptionForSearchResult:(MWKSearchResult *)result {
//                                    MWKSearchRedirectMapping *mapping = [self redirectMappingForResult:result];
//                                    if (!mapping) {
//                                        return [result.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.searchSiteURL.wmf_language];
//                                    }
//                                    
//                                    NSString *redirectedResultMessage = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"search-result-redirected-from", nil, nil, @"Redirected from: %1$@", @"Text for search result letting user know if a result is a redirect from another article. Parameters:\n* %1$@ - article title the current search result redirected from"), mapping.redirectFromTitle];
//                                    
//                                    if (!result.wikidataDescription) {
//                                        return redirectedResultMessage;
//                                    } else {
//                                        return [NSString stringWithFormat:@"%@\n%@", redirectedResultMessage, [result.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.searchSiteURL.wmf_language]];
//                                    }
//                                    }
//                                    
//                                    - (WMFEmptyViewType)emptyViewType {
//                                        return WMFEmptyViewTypeNone; //Is controlled by the search VC
//                                        }
//                                        
//                                        - (NSString *)analyticsContext {
//                                            return @"Search";
//                                            }
//                                            
//                                            - (NSString *)analyticsName {
//                                                return [self analyticsContext];
//                                                }
//                                                
//                                                - (BOOL)isDisplayingResultsForSearchTerm:(NSString *)searchTerm fromSiteURL:(NSURL *)siteURL {
//                                                    return (
//                                                        self.searchResults.results.count > 0 && // we have results already
//                                                            [self.searchSiteURL wmf_isEqualToIgnoringScheme:siteURL] && // results are from same search site url
//                                                            [self.searchResults.searchTerm isEqualToString:searchTerm] // results are for same search term
//                                                    );
//                                                    }
//                                                    
//                                                    - (MWKSavedPageList *)savedPageList {
//                                                        return self.userDataStore.savedPageList;
//                                                        }
//                                                        
//                                                        - (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//                                                            WMFArticleListTableViewRowActions *rowActions = [[WMFArticleListTableViewRowActions alloc] init];
//                                                            [rowActions applyTheme:self.theme];
//                                                            
//                                                            NSURL *url = [self urlAtIndexPath:indexPath];
//                                                            MWKSavedPageList *savedPageList = [self.userDataStore savedPageList];
//                                                            
//                                                            BOOL isItemSaved = [[self savedPageList] isSaved:[self urlAtIndexPath:indexPath]];
//                                                            
//                                                            UITableViewRowAction *share = [rowActions actionFor:ArticleListTableViewRowActionTypeShare
//                                                            at:indexPath
//                                                            in:tableView
//                                                            perform:^(NSIndexPath *indexPath) {
//                                                            [self shareArticle:url];
//                                                            }];
//                                                            
//                                                            NSMutableArray *actions = [[NSMutableArray alloc] initWithObjects:share, nil];
//                                                            
//                                                            if (isItemSaved) {
//                                                                UITableViewRowAction *unsave = [rowActions actionFor:ArticleListTableViewRowActionTypeUnsave
//                                                                    at:indexPath
//                                                                    in:tableView
//                                                                    perform:^(NSIndexPath *indexPath) {
//                                                                    [savedPageList removeEntryWithURL:url];
//                                                                    }];
//                                                                [actions addObject:unsave];
//                                                            } else {
//                                                                UITableViewRowAction *save = [rowActions actionFor:ArticleListTableViewRowActionTypeSave
//                                                                    at:indexPath
//                                                                    in:tableView
//                                                                    perform:^(NSIndexPath *indexPath) {
//                                                                    [savedPageList addSavedPageWithURL:url];
//                                                                    }];
//                                                                [actions addObject:save];
//                                                            }
//                                                            
//                                                            return actions;
//}
//
//@end
//
