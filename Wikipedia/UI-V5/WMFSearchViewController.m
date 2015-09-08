#import "WMFSearchViewController.h"

#import "RecentSearchesViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"

#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "MediaWikiKit.h"

#import <Masonry/Masonry.h>
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
    [self updateRecentSearchesVisibility:YES];

    [self.delegate searchController:self searchStateDidChange:self.state];
}

- (void)updateRecentSearchesVisibility {
    [self updateRecentSearchesVisibility:YES];
}

- (BOOL)isRecentSearchesHidden {
    return self.recentSearchesContainerView.alpha < 0.01;
}

- (void)updateRecentSearchesVisibility:(BOOL)animated {
    BOOL hideRecentSearches =
        [self.searchBar.text length] > 0 || self.recentSearchesViewController.recentSearchesItemCount == 0;

    /*
       HAX: Need to show/hide superviews since recent & results are in the same container. should use UIViewController
          containment/transition API instead in the future.
     */
    if ([self isRecentSearchesHidden] == hideRecentSearches) {
        return;
    }

    [UIView animateWithDuration:animated ? [CATransaction animationDuration] : 0.0
                     animations:^{
        self.recentSearchesContainerView.alpha = hideRecentSearches ? 0.0 : 1.0;
        self.resultsListContainerView.alpha = 1.0 - self.recentSearchesContainerView.alpha;
    }];
}

- (void)configureArticleList {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    self.resultsListController.dataStore   = self.dataStore;
    self.resultsListController.recentPages = self.recentPages;
    self.resultsListController.savedPages  = self.savedPages;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // TODO: localize
    self.title                                                    = @"Search";
    self.resultsListController.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    SelfSizingWaterfallCollectionViewLayout* resultLayout = [self.resultsListController flowLayout];
    resultLayout.minimumLineSpacing = 5.f;
    [self updateUIWithResults:nil];

    // TODO: localize
    [self.searchBar setPlaceholder:@"Search Wikipedia"];
    self.searchBar.tintColor       = [UIColor darkGrayColor];
    self.searchBar.searchBarStyle  = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor colorWithRed:0.9294 green:0.9294 blue:0.9294 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateRecentSearchesVisibility:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
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
    [self updateRecentSearchesVisibility:YES];

    [self.searchBar setShowsCancelButton:YES animated:YES];

    if (![[self currentSearchTerm] isEqualToString:self.searchBar.text]) {
        [self searchForSearchTerm:self.searchBar.text];
    }
}

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    if ([searchText length] == 0) {
        [self didCancelSearch];
        return;
    }

    [self updateRecentSearchesVisibility:YES];

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        if ([searchText isEqualToString:self.searchBar.text]) {
            [self searchForSearchTerm:searchText];
        }
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar*)searchBar {
    [self updateRecentSearchesVisibility];
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [self updateRecentSearchesVisibility];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self updateSearchStateAndNotifyDelegate:WMFSearchStateInactive];
    [self.searchBar resignFirstResponder];
    [self didCancelSearch];
}

#pragma mark - Search

- (void)didCancelSearch {
    self.searchBar.text = nil;
    [self updateSearchSuggestion:nil];
    self.resultsListController.dataSource = nil;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self updateRecentSearchesVisibility];
}

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
    [self.searchBar setShowsCancelButton:YES animated:YES];
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
