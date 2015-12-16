#import "WMFSearchViewController.h"

#import "RecentSearchesViewController.h"
#import "WMFArticleListTableViewController.h"

#import "SessionSingleton.h"

#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"
#import "WMFSearchDataSource.h"

#import "MediaWikiKit.h"

#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Wikipedia-Swift.h"

#import "UIViewController+WMFStoryboardUtilities.h"
#import "NSString+Extras.h"
#import "NSString+FormattedAttributedString.h"
#import "UIButton+WMFButton.h"
#import "UIImage+WMFStyle.h"

#import "LanguagesViewController.h"
#import "UIViewController+WMFEmptyView.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController ()
<UISearchBarDelegate,
 WMFRecentSearchesViewControllerDelegate,
 UITextFieldDelegate,
 WMFArticleSelectionDelegate,
 LanguageSelectionDelegate>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong) NSArray* searchLanguages;

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;
@property (nonatomic, strong) WMFArticleListTableViewController* resultsListController;

@property (strong, nonatomic) IBOutlet UITextField* searchField;
@property (strong, nonatomic) IBOutlet UIButton* searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView* resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView* recentSearchesContainerView;
@property (weak, nonatomic) IBOutlet UIView* separatorView;
@property (weak, nonatomic) IBOutlet UIButton* closeButton;
@property (strong, nonatomic) IBOutlet UIButton* languageOneButton;
@property (strong, nonatomic) IBOutlet UIButton* languageTwoButton;
@property (strong, nonatomic) IBOutlet UIButton* languageThreeButton;
@property (strong, nonatomic) IBOutlet UIButton* otherLanguagesButton;
@property (strong, nonatomic)IBOutletCollection(UIButton) NSArray * languageButtons;

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
    return [[(WMFSearchDataSource*)self.resultsListController.dataSource searchResults] searchTerm];
}

- (NSString*)searchSuggestion {
    return [[(WMFSearchDataSource*)self.resultsListController.dataSource searchResults] searchSuggestion];
}

- (WMFSearchFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[WMFSearchFetcher alloc] init];
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

- (void)setSearchFieldText:(NSString*)text {
    self.searchField.text = text;
    [self setSeparatorViewHidden:text.length == 0 animated:YES];
}

#pragma mark - Setup

- (void)configureArticleList {
    self.resultsListController.dataStore = self.dataStore;
    self.resultsListController.delegate  = self;
}

- (void)configureRecentSearchList {
    self.recentSearchesViewController.recentSearches = self.dataStore.userDataStore.recentSearchList;
    self.recentSearchesViewController.delegate       = self;
}

- (void)configureSearchField {
    [self setSeparatorViewHidden:YES animated:NO];
    [self.searchField setPlaceholder:MWLocalizedString(@"search-field-placeholder-text", nil)];
}

- (void)configureLanguageButtons {
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        obj.tintColor = [UIColor wmf_blueTintColor];
    }];
    UIImage* buttonBackground = [UIImage wmf_imageFromColor:[UIColor whiteColor]];
    [self.otherLanguagesButton setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [self.otherLanguagesButton setTitle:MWLocalizedString(@"main-menu-title", nil) forState:UIControlStateNormal];
    [self.otherLanguagesButton sizeToFit];

    [self updateLanguageButtonsToPreferredLanguages];
    [self selectLanguageForSite:self.searchSite];
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureSearchField];
    [self configureLanguageButtons];

    // move search field offscreen, preparing for transition in viewWillAppear
    self.searchFieldTop.constant = -self.searchFieldHeight.constant;

    self.title                                               = MWLocalizedString(@"search-title", nil);
    self.resultsListController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.resultsListController.tableView.backgroundColor     = [UIColor clearColor];

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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!self.presentedViewController) {
        /*
           Only perform animations & search site sync if search is being modally dismissed (as opposed to having another
           view presented on top of it.
         */
        [self saveLastSearch];
        [self saveSearchlanguage];

        self.searchFieldTop.constant = -self.searchFieldHeight.constant;

        [self.transitionCoordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
            [self.searchField resignFirstResponder];
            [self.view layoutIfNeeded];
        } completion:nil];
    }
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self resizeLanguageButtonsIfNeeded];
    } completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListTableViewController class]]) {
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

    DDLogDebug(@"Search field text changed to: %@", query);

    BOOL isFieldEmpty = [query wmf_trim].length == 0;
    [self setSeparatorViewHidden:isFieldEmpty animated:YES];

    if (isFieldEmpty) {
        [self didCancelSearch];
        return;
    }

    [self setRecentSearchesHidden:YES animated:YES];

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        if ([query isEqualToString:self.searchField.text]) {
            DDLogDebug(@"Searching for %@ after delay.", query);
            [self searchForSearchTerm:query];
        } else {
            DDLogInfo(@"Aborting search for %@ since query has changed to %@", query, self.searchField.text);
        }
    });
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self saveLastSearch];
    [self updateRecentSearchesVisibility];
    [self.resultsListController wmf_hideEmptyView];
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
    [self.resultsListController wmf_hideEmptyView];
}

- (void)searchForSearchTerm:(NSString*)searchTerm {
    if ([searchTerm wmf_trim].length == 0) {
        DDLogDebug(@"Ignoring whitespace-only query.");
        return;
    }
    @weakify(self);
    [self.resultsListController wmf_hideEmptyView];
    [self.fetcher fetchArticlesForSearchTerm:searchTerm site:self.searchSite resultLimit:WMFMaxSearchResultLimit].thenOn(dispatch_get_main_queue(), ^id (WMFSearchResults* results){
        @strongify(self);
        if (![results.searchTerm isEqualToString:self.searchField.text]) {
            return [NSError cancelledError];
        }

        /*
           HAX: must set dataSource before starting the animation since dataSource is _unsafely_ assigned to the
           collection view, meaning there's a chance the collectionView accesses deallocated memory during an animation
         */
        WMFSearchDataSource* dataSource =
            [[WMFSearchDataSource alloc] initWithSearchSite:self.searchSite searchResults:results];

        self.resultsListController.dataSource = dataSource;

        [UIView animateWithDuration:0.25 animations:^{
            [self updateUIWithResults:results];
        }];

        if ([results.results count] < kWMFMinResultsBeforeAutoFullTextSearch) {
            return [self.fetcher fetchArticlesForSearchTerm:searchTerm
                                                       site:self.searchSite
                                                resultLimit:WMFMaxSearchResultLimit
                                             fullTextSearch:YES
                                    appendToPreviousResults:results];
        }
        return [AnyPromise promiseWithValue:results];
    }).then(^(WMFSearchResults* results){
        if ([searchTerm isEqualToString:results.searchTerm]) {
            if (results.results.count == 0) {
                dispatchOnMainQueueAfterDelayInSeconds(0.25, ^{
                    //Without the delay there is a weird animation due to the table also reloading simultaneously
                    [self.resultsListController wmf_showEmptyViewOfType:WMFEmptyViewTypeNoSearchResults];
                });
                [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"search-no-matches", nil) sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
            }
        }

        // change recent search visibility if no prefix results returned, and update suggestion if needed
        [UIView animateWithDuration:0.25 animations:^{
            [self updateUIWithResults:results];
        }];
    }).catch(^(NSError* error){
        @strongify(self);
        if ([searchTerm isEqualToString:self.searchField.text]) {
            [self.resultsListController wmf_showEmptyViewOfType:WMFEmptyViewTypeNoSearchResults];
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
            DDLogError(@"Encountered search error: %@", error);
        }
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

#pragma mark - Languages

- (void)saveSearchlanguage {
    [[SessionSingleton sharedInstance] setSearchLanguage:self.searchSite.language];
}

- (NSArray*)allLanguagesFromController {
    NSMutableArray* lang = [NSMutableArray array];
    [lang addObjectsFromArray:[MWKLanguageLinkController sharedInstance].preferredLanguages];
    [lang addObjectsFromArray:[MWKLanguageLinkController sharedInstance].otherLanguages];
    return lang;
}

- (void)updateLanguages {
    NSArray* languages = [self allLanguagesFromController];
    self.searchLanguages = [languages wmf_arrayByTrimmingToLength:3];
}

- (void)updateLanguageButtonsToPreferredLanguages {
    [self updateLanguages];
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [obj setTitle:[(MWKLanguageLink*)self.searchLanguages[idx] localizedName]  forState:UIControlStateNormal];
    }];
    [self resizeLanguageButtonsIfNeeded];
}

/**
 *  HACK: Auto layout is not possible in the tool bar.
 *  This truncates text of language buttons if they are larger than the display
 */
- (void)resizeLanguageButtonsIfNeeded {
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [obj sizeToFit];
    }];
    CGFloat buttonWidth = [[self.languageButtons bk_reduce:@0 withBlock:^id (NSNumber* sum, UIButton* obj) {
        return @(obj.frame.size.width + [sum floatValue]);
    }] floatValue];
    buttonWidth += self.otherLanguagesButton.frame.size.width;

    //6 leaves us 2 pixels between each button
    if (buttonWidth > self.view.frame.size.width - 6) {
        [self.languageButtons enumerateObjectsUsingBlock:^(UIButton* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
            CGRect f = obj.frame;
            f.size.width -= (buttonWidth - (self.view.frame.size.width - 6)) / 3;
            obj.frame = f;
        }];
    }
}

- (void)selectLanguageForSite:(MWKSite*)site {
    self.searchSite = site;
    [self.searchLanguages enumerateObjectsUsingBlock:^(MWKLanguageLink* _Nonnull language, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([[language site] isEqual:site]) {
            UIButton* buttonToSelect = self.languageButtons[idx];
            [self.languageButtons enumerateObjectsUsingBlock:^(UIButton* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                if (obj == buttonToSelect) {
                    [obj setSelected:YES];
                } else {
                    [obj setSelected:NO];
                }
            }];
        }
    }];
    NSString* query = self.searchField.text;
    [self searchForSearchTerm:query];
}

- (void)selectLanguageForButton:(UIButton*)button {
    NSUInteger index = [self.languageButtons indexOfObject:button];
    NSAssert(index != NSNotFound, @"language button not found for language!");
    if (index != NSNotFound) {
        MWKLanguageLink* lang = self.searchLanguages[index];
        [self selectLanguageForSite:lang.site];
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

- (IBAction)setLanguageWithSender:(id)sender {
    [self selectLanguageForButton:sender];
}

- (IBAction)openLanguagePicker:(id)sender {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:NULL];
}

#pragma mark - WMFArticleSelectionDelegate

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self.searchResultDelegate didSelectTitle:title sender:self discoveryMethod:discoveryMethod];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self.searchResultDelegate didCommitToPreviewedArticleViewController:articleViewController sender:self];
}

#pragma mark - LanguageSelectionDelegate

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self updateLanguageButtonsToPreferredLanguages];
    [self selectLanguageForSite:language.site];
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString*)analyticsName {
    return @"Search";
}

@end
