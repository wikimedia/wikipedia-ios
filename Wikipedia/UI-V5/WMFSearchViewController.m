#import "WMFSearchViewController.h"

#import "RecentSearchesViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "MediaWikiKit.h"

#import <Masonry/Masonry.h>
#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <PiwikTracker/PiwikTracker.h>
#import "Wikipedia-Swift.h"

#import "UIViewController+WMFStoryboardUtilities.h"
#import "NSString+FormattedAttributedString.h"
#import "UIViewController+Alert.h"
#import "UIButton+WMFButton.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController ()
<UISearchBarDelegate,
 WMFRecentSearchesViewControllerDelegate,
 WMFArticleListTransitionProvider,
 UITextFieldDelegate>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;
@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;

@property (strong, nonatomic) IBOutlet UITextField* searchField;
@property (strong, nonatomic) IBOutlet UIButton* searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView* resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView* recentSearchesContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* contentViewTop;

@property (nonatomic, strong) WMFSearchFetcher* fetcher;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* suggestionButtonHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* searchFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* searchFieldTop;

@property (nonatomic, assign, getter = isRecentSearchesHidden) BOOL recentSearchesHidden;

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated;

@end

@implementation WMFSearchViewController

+ (instancetype)searchViewControllerWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    WMFSearchViewController* searchVC = [self wmf_initialViewControllerFromClassStoryboard];
    searchVC.searchSite             = site;
    searchVC.dataStore              = dataStore;
    searchVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    searchVC.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    return searchVC;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

#pragma mark - Accessors

- (WMFArticleListTransition*)listTransition {
    return self.resultsListController.listTransition;
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
}

- (void)configureRecentSearchList {
    self.recentSearchesViewController.recentSearches = self.dataStore.userDataStore.recentSearchList;
    self.recentSearchesViewController.delegate       = self;
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)configureSearchField {
    @weakify(self);
    self.searchField.rightView = [UIButton wmf_buttonType:WMFButtonTypeX handler:^(id sender) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    self.searchField.rightViewMode = UITextFieldViewModeAlways;

    // TODO: localize
    [self.searchField setPlaceholder:@"Search Wikipedia"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureSearchField];

    // TODO: localize
    self.title                                                    = @"Search";
    self.resultsListController.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    SelfSizingWaterfallCollectionViewLayout* resultLayout = [self.resultsListController flowLayout];
    resultLayout.minimumLineSpacing = 5.f;
    [self updateUIWithResults:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.searchFieldTop.constant = -self.searchFieldHeight.constant;
    self.contentViewTop.constant = self.view.bounds.size.height;
    [self.view layoutIfNeeded];
    BOOL willAnimate = [self.transitionCoordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self.searchFieldTop setConstant:0];
        self.contentViewTop.constant = self.searchFieldHeight.constant;
        [self.view layoutIfNeeded];
        [self updateRecentSearchesVisibility:animated];
    }
                                                                   completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull transitionContext) {
        [self.searchField becomeFirstResponder];
    }];
    NSParameterAssert(willAnimate);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] sendView:@"Search"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveLastSearch];
    [self.transitionCoordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self.searchField resignFirstResponder];
        self.searchFieldTop.constant = -self.searchFieldHeight.constant;
        self.contentViewTop.constant = self.view.bounds.size.height;
        [self.view layoutIfNeeded];
    } completion:nil];
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

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    if (![[self currentSearchTerm] isEqualToString:textField.text]) {
        [self searchForSearchTerm:textField.text];
    }
}

- (IBAction)textFieldDidChange {
    NSString* query = self.searchField.text;
    if ([query wmf_trim].length == 0) {
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
    self.searchField.text = nil;
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
        [self.dataStore.userDataStore.recentSearchList addEntry:entry];
        [self.dataStore.userDataStore.recentSearchList save];
        [self.recentSearchesViewController reloadRecentSearches];
    }
}

#pragma mark - WMFRecentSearchesViewControllerDelegate

- (void)recentSearchController:(RecentSearchesViewController*)controller didSelectSearchTerm:(MWKRecentSearchEntry*)searchTerm {
    self.searchField.text = searchTerm.searchTerm;
    [self searchForSearchTerm:searchTerm.searchTerm];
    [self updateRecentSearchesVisibility];
}

#pragma mark - Actions

- (IBAction)searchForSuggestion:(id)sender {
    self.searchField.text = [self searchSuggestion];
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchSuggestion:nil];
    }];
    [self searchForSearchTerm:self.searchField.text];
}

@end
