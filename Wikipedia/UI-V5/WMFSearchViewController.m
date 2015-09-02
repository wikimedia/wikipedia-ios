#import "WMFSearchViewController.h"
#import "RecentSearchesViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import <Masonry/Masonry.h>

#import "MediaWikiKit.h"

#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "NSString+FormattedAttributedString.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController ()<WMFRecentSearchesViewControllerDelegate, WMFArticleListTransitionProvider>

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;
@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;

@property (strong, nonatomic) IBOutlet UISearchBar* searchBar;
@property (strong, nonatomic) IBOutlet UIButton* searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView* resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView* recentSearchesContainerView;

@property (nonatomic, strong) WMFSearchFetcher* fetcher;

@property (nonatomic, assign, readwrite) WMFSearchState state;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* suggestionButtonHeightConstraint;

@end

@implementation WMFSearchViewController

- (WMFArticleListTransition*)listTransition {
    return self.resultsListController.listTransition;
}

- (void)setSavedPages:(MWKSavedPageList* __nonnull)savedPages {
    _savedPages = savedPages;
    // resultsListController might be nil if `prepareForSegue:sender:` hasn't been called
    self.resultsListController.savedPages = savedPages;
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    _searchSite  = searchSite;
    self.fetcher = nil;
}

- (NSString*)currentSearchTerm {
    return [(WMFSearchResults*)self.resultsListController.dataSource searchTerm];
}

- (NSString*)searchSuggestion {
    return [(WMFSearchResults*)self.resultsListController.dataSource searchSuggestion];
}

- (WMFSearchFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[WMFSearchFetcher alloc] initWithSearchSite:self.searchSite dataStore:self.dataStore];
    }

    return _fetcher;
}

- (void)updateSearchStateAndNotifyDelegate:(WMFSearchState)state {
    if (self.state == state) {
        return;
    }

    self.state = state;
    [self updateRecentSearchesVisibility];

    [self.delegate searchController:self searchStateDidChange:self.state];
}

- (void)updateRecentSearchesVisibility {
    if ([self.searchBar.text length] == 0 && self.recentSearchesViewController.recentSearchesItemCount > 0) {
        [self.recentSearchesContainerView setHidden:NO];
    } else {
        [self.recentSearchesContainerView setHidden:YES];
    }
}

- (void)configureArticleList {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    self.resultsListController.dataStore   = self.dataStore;
    self.resultsListController.recentPages = self.recentPages;
    self.resultsListController.savedPages= self.savedPages;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title                                                    = @"Search";
    self.resultsListController.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self updateUIWithResults:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateRecentSearchesVisibility];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
    [self configureSearchBar:self.searchBar];
}

- (void)configureSearchBar:(UISearchBar*)searchBar {
    [searchBar setPlaceholder:@"Search Wikipedia"];
    searchBar.tintColor       = [UIColor darkGrayColor];
    searchBar.searchBarStyle  = UISearchBarStyleMinimal;
    searchBar.backgroundColor = [UIColor colorWithRed:0.9294 green:0.9294 blue:0.9294 alpha:1.0];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.resultsListController = segue.destinationViewController;
        [self configureArticleList];
    }
    if ([segue.destinationViewController isKindOfClass:[RecentSearchesViewController class]]) {
        self.recentSearchesViewController          = segue.destinationViewController;
        self.recentSearchesViewController.delegate = self;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    [self updateSearchStateAndNotifyDelegate:WMFSearchStateActive];
    [self updateRecentSearchesVisibility];

    [self.searchBar setShowsCancelButton:YES animated:YES];

    if (![[self currentSearchTerm] isEqualToString:self.searchBar.text]) {
        [self searchForSearchTerm:self.searchBar.text];
    }
}

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    [self updateRecentSearchesVisibility];

    if ([searchText length] == 0) {
        self.resultsListController.dataSource = nil;
    }

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        if ([searchText isEqualToString:self.searchBar.text]) {
            [self searchForSearchTerm:searchText];
        }
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar*)searchBar {
    [self updateRecentSearchesVisibility];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [self updateRecentSearchesVisibility];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self updateRecentSearchesVisibility];
    [self updateSearchStateAndNotifyDelegate:WMFSearchStateInactive];
    self.searchBar.text                   = nil;
    self.resultsListController.dataSource = nil;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
}

#pragma mark - Search

- (void)searchForSearchTerm:(NSString*)searchTerm {
    dispatch_promise(^{
        return [self.fetcher searchArticleTitlesForSearchTerm:searchTerm];
    }).then((id) ^ (WMFSearchResults * results){
        /*
           HAX: must set dataSource before starting the animation since dataSource is _unsafely_ assigned to the
           collection view, meaning there's a chance the collectionView accesses deallocated memory during an animation
         */
        self.resultsListController.dataSource = results;

        [UIView animateWithDuration:0.25 animations:^{
            [self updateUIWithResults:results];
        }];

        if ([results.articles count] < kWMFMinResultsBeforeAutoFullTextSearch) {
            return [self.fetcher searchFullArticleTextForSearchTerm:searchTerm appendToPreviousResults:results];
        }

        return [AnyPromise promiseWithValue:results];
    }).then(^(WMFSearchResults* results){
        if ([searchTerm isEqualToString:results.searchTerm]) {
            self.resultsListController.dataSource = results;
            [self.recentSearchesViewController saveTerm:searchTerm forDomain:self.fetcher.searchSite.domain type:SEARCH_TYPE_TITLES];
        }
    }).catch(^(NSError* error){
        NSLog(@"%@", [error description]);
    });
}

- (void)updateUIWithResults:(WMFSearchResults*)results {
    [self updateSearchSuggestion:results.searchSuggestion];
    [self updateRecentSearchesVisibility];
}

- (void)updateSearchSuggestion:(NSString*)searchSuggestion {
    NSAttributedString* title =
        [searchSuggestion length] ? [self getAttributedStringForSuggestion : searchSuggestion] : nil;
    [self.searchSuggestionButton setAttributedTitle:title forState:UIControlStateNormal];
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    self.suggestionButtonHeightConstraint.constant =
        [self.searchSuggestionButton attributedTitleForState:UIControlStateNormal] ?
        [self.searchSuggestionButton wmf_heightAccountingForMultiLineText]
        : 0;
}

- (NSAttributedString*)getAttributedStringForSuggestion:(NSString*)suggestion {
    return [MWLocalizedString(@"search-did-you-mean", nil)
            attributedStringWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]}
                       substitutionStrings:@[suggestion]
                    substitutionAttributes:@[@{NSFontAttributeName: [UIFont italicSystemFontOfSize:18]}]];
}

#pragma mark - WMFRecentSearchesViewControllerDelegate

- (void)recentSearchController:(RecentSearchesViewController*)controller didSelectSearchTerm:(NSString*)searchTerm {
    self.searchBar.text = searchTerm;
    [self searchForSearchTerm:searchTerm];
    [self updateRecentSearchesVisibility];
}

#pragma mark - Actions

- (IBAction)searchForSuggestion:(id)sender {
    self.searchBar.text = [self searchSuggestion];
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchSuggestion:nil];
    }];

    [self searchForSearchTerm:self.searchBar.text];
}

@end
