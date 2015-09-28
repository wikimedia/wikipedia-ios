#import "WMFSearchViewController.h"

#import "RecentSearchesViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"

#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "MediaWikiKit.h"

#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"


#import "NSString+FormattedAttributedString.h"
#import "UIViewController+Alert.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController ()<WMFRecentSearchesViewControllerDelegate, WMFArticleListTransitionProvider>

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;
@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;

@property (strong, nonatomic) IBOutlet UISearchBar* searchBar;
@property (strong, nonatomic) IBOutlet UIButton* searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView* resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView* recentSearchesContainerView;

@property (nonatomic, strong) WMFSearchFetcher* fetcher;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* suggestionButtonHeightConstraint;

@property (nonatomic, assign, getter = isRecentSearchesHidden) BOOL recentSearchesHidden;

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated;

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

- (void)updateRecentSearchesVisibility {
    [self updateRecentSearchesVisibility:YES];
}

- (void)updateRecentSearchesVisibility:(BOOL)animated {
    BOOL hideRecentSearches =
        [self.searchBar.text wmf_trim].length > 0 || [self.recentSearches countOfEntries] == 0;

    [self setRecentSearchesHidden:hideRecentSearches animated:animated];
}

- (void)setRecentSearchesHidden:(BOOL)showingRecentSearches {
    [self setRecentSearchesHidden:showingRecentSearches animated:NO];
}

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated {
    /*
       HAX: Need to show/hide superviews since recent & results are in the same container. should use UIViewController
       containment/transition API instead in the future.
     */
    if (self.isRecentSearchesHidden == hidingRecentSearches) {
        return;
    }

    _recentSearchesHidden = hidingRecentSearches;

    [UIView animateWithDuration:animated ? [CATransaction animationDuration] : 0.0
                     animations:^{
        self.recentSearchesContainerView.alpha = self.isRecentSearchesHidden ? 0.0 : 1.0;
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

- (void)configureRecentSearchList {
    NSParameterAssert(self.recentSearches);
    self.recentSearchesViewController.recentSearches = self.recentSearches;
    self.recentSearchesViewController.delegate       = self;
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveLastSearch];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.resultsListController = segue.destinationViewController;
        [self configureArticleList];
    }
    if ([segue.destinationViewController isKindOfClass:[RecentSearchesViewController class]]) {
        self.recentSearchesViewController = segue.destinationViewController;
        [self configureRecentSearchList];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];

    if (![[self currentSearchTerm] isEqualToString:self.searchBar.text]) {
        [self searchForSearchTerm:self.searchBar.text];
    }
}

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    if ([searchText wmf_trim].length == 0) {
        [self didCancelSearch];
        return;
    }

    [self.searchBar setShowsCancelButton:YES animated:YES];

    [self setRecentSearchesHidden:YES animated:YES];

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        if ([searchText isEqualToString:self.searchBar.text]) {
            [self searchForSearchTerm:searchText];
        }
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar*)searchBar {
    [self.searchBar setShowsCancelButton:searchBar.text.length animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [self saveLastSearch];
    [self updateRecentSearchesVisibility];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self saveLastSearch];
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self didCancelSearch];
}

#pragma mark - Search

- (void)didCancelSearch {
    self.searchBar.text = nil;
    [self updateSearchSuggestion:nil];
    self.resultsListController.dataSource = nil;
    [self updateRecentSearchesVisibility];
}

- (void)searchForSearchTerm:(NSString*)searchTerm {
    if ([searchTerm wmf_trim].length == 0) {
        return;
    }
    @weakify(self);
    [self.fetcher searchArticleTitlesForSearchTerm:searchTerm]
    .thenOn(dispatch_get_main_queue(), ^id (WMFSearchResults* results){
        @strongify(self);
        if (![results.searchTerm isEqualToString:self.searchBar.text]) {
            return [NSError cancelledError];
        }

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
            if (results.articles.count == 0) {
                [self showAlert:MWLocalizedString(@"search-no-matches", nil) type:ALERT_TYPE_TOP duration:2.0];
            }
            self.resultsListController.dataSource = results;
        }
    }).catch(^(NSError* error){
        [self showAlert:error.userInfo[NSLocalizedDescriptionKey] type:ALERT_TYPE_TOP duration:2.0];

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

#pragma mark - RecentSearches

- (void)saveLastSearch {
    if ([self currentSearchTerm]) {
        MWKRecentSearchEntry* entry = [[MWKRecentSearchEntry alloc] initWithSite:self.searchSite searchTerm:[self currentSearchTerm]];
        [self.recentSearches addEntry:entry];
        [self.recentSearches save];
        [self.recentSearchesViewController reloadRecentSearches];
    }
}

#pragma mark - WMFRecentSearchesViewControllerDelegate

- (void)recentSearchController:(RecentSearchesViewController*)controller didSelectSearchTerm:(MWKRecentSearchEntry*)searchTerm {
    self.searchBar.text = searchTerm.searchTerm;
    [self searchForSearchTerm:searchTerm.searchTerm];
    [self updateRecentSearchesVisibility];
}

#pragma mark - Actions

- (IBAction)searchForSuggestion:(id)sender {
    self.searchBar.text = [self searchSuggestion];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchSuggestion:nil];
    }];
    [self searchForSearchTerm:self.searchBar.text];
}

@end
