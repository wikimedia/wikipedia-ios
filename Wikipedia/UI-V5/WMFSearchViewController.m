#import "WMFSearchViewController.h"

#import "RecentSearchesViewController.h"
#import "WMFArticleListCollectionViewController.h"

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "MediaWikiKit.h"

#import <Masonry/Masonry.h>
#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <PiwikTracker/PiwikTracker.h>
#import "Wikipedia-Swift.h"

#import "UIViewController+WMFStoryboardUtilities.h"
#import "NSString+Extras.h"
#import "NSString+FormattedAttributedString.h"
#import "UIViewController+Alert.h"
#import "UIButton+WMFButton.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController ()
<UISearchBarDelegate,
 WMFRecentSearchesViewControllerDelegate,
 UITextFieldDelegate,
 WMFArticleSelectionDelegate>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;
@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;

@property (strong, nonatomic) IBOutlet UITextField* searchField;
@property (strong, nonatomic) IBOutlet UIButton* searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView* resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView* recentSearchesContainerView;
@property (weak, nonatomic) IBOutlet UIView* separatorView;
@property (weak, nonatomic) IBOutlet UIButton* closeButton;

@property (nonatomic, strong) WMFSearchFetcher* fetcher;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* suggestionButtonHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* searchFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* searchFieldTop;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* contentViewTop;


@property (nonatomic, assign, getter = isRecentSearchesHidden) BOOL recentSearchesHidden;

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated;

/**
 *  Set the text of the search field programatically.
 *
 *  Sets the text on the receiver's @c searchField and updates the vertical separator's visibility.  This is solely
 *  for cases when the user searches for something without typing it manually or clearing the search field.
 *
 *  @warning Use this instead of setting @c searchField.text directly.
 *
 *  @param text The string to show in the search field.
 */
- (void)setSearchFieldText:(NSString*)text;

@end

@implementation WMFSearchViewController

+ (instancetype)searchViewControllerWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    NSParameterAssert(dataStore);
    WMFSearchViewController* searchVC = [self wmf_initialViewControllerFromClassStoryboard];
    searchVC.searchSite             = site;
    searchVC.dataStore              = dataStore;
    searchVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    searchVC.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    return searchVC;
}

#pragma mark - Accessors

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
        [self.searchField.text wmf_trim].length > 0 || [self.dataStore.userDataStore.recentSearchList countOfEntries] == 0;

    [self setRecentSearchesHidden:hideRecentSearches animated:animated];
}

- (void)setRecentSearchesHidden:(BOOL)showingRecentSearches {
    [self setRecentSearchesHidden:showingRecentSearches animated:NO];
}

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated {
    if (self.isRecentSearchesHidden == hidingRecentSearches) {
        return;
    }

    _recentSearchesHidden = hidingRecentSearches;

    [UIView animateWithDuration:animated ? [CATransaction animationDuration] : 0.0
                          delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.recentSearchesContainerView.alpha = self.isRecentSearchesHidden ? 0.0 : 1.0;
        self.resultsListContainerView.alpha = 1.0 - self.recentSearchesContainerView.alpha;
    } completion:nil];
}

- (void)configureArticleList {
    self.resultsListController.dataStore   = self.dataStore;
    self.resultsListController.recentPages = self.dataStore.userDataStore.historyList;
    self.resultsListController.savedPages  = self.dataStore.userDataStore.savedPageList;
    self.resultsListController.delegate    = self;
}

- (void)configureRecentSearchList {
    self.recentSearchesViewController.recentSearches = self.dataStore.userDataStore.recentSearchList;
    self.recentSearchesViewController.delegate       = self;
}

- (void)setSearchFieldText:(NSString*)text {
    self.searchField.text = text;
    [self setSeparatorViewHidden:text.length == 0 animated:YES];
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)configureSearchField {
    [self setSeparatorViewHidden:YES animated:NO];
    // TODO: localize
    [self.searchField setPlaceholder:@"Search Wikipedia"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureSearchField];

    // move search field offscreen, preparing for transition in viewWillAppear
    self.searchFieldTop.constant = -self.searchFieldHeight.constant;

    // TODO: localize
    self.title                                                    = @"Search";
    self.resultsListController.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    SelfSizingWaterfallCollectionViewLayout* resultLayout = [self.resultsListController flowLayout];
    resultLayout.minimumLineSpacing                           = 0.f;
    resultLayout.minimumInteritemSpacing                      = 0.f;
    resultLayout.sectionInset                                 = UIEdgeInsetsZero;
    self.resultsListController.collectionView.backgroundColor = [UIColor clearColor];

    [self updateUIWithResults:nil];
    [self updateRecentSearchesVisibility:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.searchFieldTop.constant = 0;
    [self.view setNeedsUpdateConstraints];

    [self.transitionCoordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self.view layoutIfNeeded];
        [self.searchField becomeFirstResponder];
    } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] sendView:@"Search"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveLastSearch];

    self.searchFieldTop.constant = -self.searchFieldHeight.constant;

    [self.transitionCoordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self.searchField resignFirstResponder];
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)willTransitionToTraitCollection:(UITraitCollection*)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    if (self.traitCollection.verticalSizeClass != newCollection.verticalSizeClass) {
        [self.view setNeedsUpdateConstraints];
        [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
            [self.view layoutSubviews];
        } completion:nil];
    }
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

#pragma mark - Separator View

- (void)setSeparatorViewHidden:(BOOL)hidden animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        self.separatorView.alpha = hidden ? 0.0 : 1.0;
    }];
}

#pragma mark - Dismissal

- (IBAction)didTapCloseButton:(id)sender {
    [self.searchField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    if (![[self currentSearchTerm] isEqualToString:textField.text]) {
        [self searchForSearchTerm:textField.text];
    }
}

- (IBAction)textFieldDidChange {
    NSString* query = self.searchField.text;

    BOOL isFieldEmpty = [query wmf_trim].length == 0;
    [self setSeparatorViewHidden:isFieldEmpty animated:YES];

    if (isFieldEmpty) {
        [self didCancelSearch];
        return;
    }

    [self setRecentSearchesHidden:YES animated:YES];

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        if ([query isEqualToString:self.searchField.text]) {
            [self searchForSearchTerm:query];
        }
    });
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self saveLastSearch];
    [self updateRecentSearchesVisibility];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
    [self didCancelSearch];
    return YES;
}

#pragma mark - Search

- (void)didCancelSearch {
    [self setSearchFieldText:nil];
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
        if (![results.searchTerm isEqualToString:self.searchField.text]) {
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

- (CGFloat)searchFieldHeightForCurrentTraitCollection {
    return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 44 : 64;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    self.searchFieldHeight.constant = [self searchFieldHeightForCurrentTraitCollection];

    self.contentViewTop.constant = self.searchFieldHeight.constant;

    self.suggestionButtonHeightConstraint.constant =
        [self.searchSuggestionButton attributedTitleForState:UIControlStateNormal].length > 0 ?
        [self.searchSuggestionButton wmf_heightAccountingForMultiLineText] : 0;
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
        MWKRecentSearchEntry* entry = [[MWKRecentSearchEntry alloc] initWithSite:self.searchSite
                                                                      searchTerm:[self currentSearchTerm]];
        [self.dataStore.userDataStore.recentSearchList addEntry:entry];
        [self.dataStore.userDataStore.recentSearchList save];
        [self.recentSearchesViewController reloadRecentSearches];
    }
}

#pragma mark - WMFRecentSearchesViewControllerDelegate

- (void)recentSearchController:(RecentSearchesViewController*)controller
           didSelectSearchTerm:(MWKRecentSearchEntry*)searchTerm {
    [self setSearchFieldText:searchTerm.searchTerm];
    [self searchForSearchTerm:searchTerm.searchTerm];
    [self updateRecentSearchesVisibility];
}

#pragma mark - Actions

- (IBAction)searchForSuggestion:(id)sender {
    [self setSearchFieldText:[self searchSuggestion]];
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchSuggestion:nil];
    }];
    [self searchForSearchTerm:self.searchField.text];
}

#pragma mark - WMFArticleSelectionDelegate

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self.searchResultDelegate didSelectTitle:title sender:self discoveryMethod:discoveryMethod];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self.searchResultDelegate didCommitToPreviewedArticleViewController:articleViewController sender:self];
}

@end
