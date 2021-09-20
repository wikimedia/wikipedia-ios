#import "WMFLanguagesViewController.h"
@import WMF;
#import "MWKTitleLanguageController.h"
#import "WMFLanguageCell.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "Wikipedia-Swift.h"
#import "WMFArticleLanguagesSectionHeader.h"
#import "WMFArticleLanguagesSectionFooter.h"
#import "WMFLanguagesViewControllerDelegate.h"

static const NSTimeInterval WMFActivityCompletionAnimationDuration = 0.15;
static CGFloat const WMFOtherLanguageRowHeight = 138.f;
static CGFloat const WMFLanguageHeaderHeight = 57.f;

@interface WMFLanguagesViewController () <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *languageFilterField;
@property (strong, nonatomic) MWKLanguageFilter *languageFilter;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *languageFilterTopSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *filterDividerHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *filterHeightConstraint;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL hideLanguageFilter;
@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL disableSelection;

// The showAllLangugages and showPreferredLanguages settings are mutually exclusive.
// Only one of the two should be set to YES.
@property (nonatomic, assign) BOOL showAllLanguages;
@property (nonatomic, assign) BOOL showPreferredLanguages;
@property (nonatomic, assign) BOOL showNonPreferredLanguages;

@property (nonatomic, strong) WMFTheme *theme;

@end

@implementation WMFLanguagesViewController {
  @public
    MWKLanguageFilter *_languageFilter;
}

@synthesize languageFilter = _languageFilter;

+ (instancetype)languagesViewController {
    WMFLanguagesViewController *languagesVC = [[WMFLanguagesViewController alloc] initWithNibName:@"WMFLanguagesViewController" bundle:nil];
    NSParameterAssert(languagesVC);

    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"article-languages-label", nil, nil, @"Choose language", @"Header label for per-article language selector screen. {{Identical|Choose language}}");
    languagesVC.editing = NO;
    return languagesVC;
}

+ (instancetype)nonPreferredLanguagesViewController {
    WMFLanguagesViewController *languagesVC = [[WMFLanguagesViewController alloc] initWithNibName:@"WMFLanguagesViewController" bundle:nil];
    NSParameterAssert(languagesVC);

    languagesVC.title = [WMFCommonStrings wikipediaLanguages];
    languagesVC.editing = NO;
    languagesVC.showPreferredLanguages = NO;

    return languagesVC;
}

+ (instancetype)allLanguagesViewController {
    WMFLanguagesViewController *languagesVC = [[WMFLanguagesViewController alloc] initWithNibName:@"WMFLanguagesViewController" bundle:nil];
    NSParameterAssert(languagesVC);

    languagesVC.title = [WMFCommonStrings wikipediaLanguages];
    languagesVC.editing = NO;
    languagesVC.showAllLanguages = YES;
    languagesVC.showPreferredLanguages = NO;
    languagesVC.showNonPreferredLanguages = NO;

    return languagesVC;
}

- (void)setup {
    _showNonPreferredLanguages = YES;
    _showPreferredLanguages = YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }

    NSAssert(self.title, @"Don't forget to set a title!");

    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = WMFOtherLanguageRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    // stylize
    if ([self.languageFilterField respondsToSelector:@selector(setReturnKeyType:)]) {
        [self.languageFilterField setReturnKeyType:UIReturnKeyDone];
    }

    self.languageFilterField.placeholder = WMFLocalizedStringWithDefaultValue(@"article-languages-filter-placeholder", nil, nil, @"Find language", @"Filter languages text box placeholder text.");

    self.filterDividerHeightConstraint.constant = 0.5f;

    [self.tableView registerNib:[WMFLanguageCell wmf_classNib] forCellReuseIdentifier:[WMFLanguageCell wmf_nibName]];
    [self.tableView registerNib:[WMFArticleLanguagesSectionHeader wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];
    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];

    //HAX: force these to take effect if they were set before the VC was presented/pushed.
    self.editing = self.editing;
    self.hideLanguageFilter = self.hideLanguageFilter;
    self.disableSelection = self.disableSelection;

    [self applyTheme:self.theme];
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:self.userDismissalCompletionBlock];
}

- (void)setHideLanguageFilter:(BOOL)hideLanguageFilter {
    _hideLanguageFilter = hideLanguageFilter;
    self.filterHeightConstraint.constant = hideLanguageFilter ? 0 : 44;
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
    self.tableView.editing = editing;
}

- (void)setDisableSelection:(BOOL)disableSelection {
    _disableSelection = disableSelection;
    self.tableView.allowsSelection = !disableSelection;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadLanguages];
}

#pragma mark - Language Loading

- (void)loadLanguages {
    [self reloadDataSections];
}

#pragma mark - Top menu

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Section management

- (void)reloadDataSections {
    [[WMFAlertManager sharedInstance] dismissAlert];
    [self.tableView reloadData];
}

- (BOOL)isAllLanguagesSection:(NSInteger)section {
    if (self.showAllLanguages) {
        NSAssert(self.showAllLanguages == NO || self.showPreferredLanguages == NO, @"The values showAllLanguages and showPreferredLanguages are mutually exclusive.");
        if (section == 0) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isPreferredSection:(NSInteger)section {
    if (self.showPreferredLanguages) {
        NSAssert(self.showAllLanguages == NO || self.showPreferredLanguages == NO, @"The values showAllLanguages and showPreferredLanguages are mutually exclusive.");
        if (section == 0) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isFilteredPreferredLanguage:(MWKLanguageLink *)language {
    return [self.languageFilter.filteredPreferredLanguages containsObject:language];
}

- (BOOL)isExploreFeedCustomizationSettingsSection:(NSInteger)section {
    return section == 1;
}

- (void)setShowAllLanguages:(BOOL)showAllLanguages {
    if (_showAllLanguages == showAllLanguages) {
        return;
    }
    _showAllLanguages = showAllLanguages;
    [self reloadDataSections];
}

- (void)setShowPreferredLanguages:(BOOL)showPreferredLanguages {
    if (_showPreferredLanguages == showPreferredLanguages) {
        return;
    }
    _showPreferredLanguages = showPreferredLanguages;
    [self reloadDataSections];
}

- (void)setShowNonPreferredLanguages:(BOOL)showNonPreferredLanguages {
    if (_showNonPreferredLanguages == showNonPreferredLanguages) {
        return;
    }
    _showNonPreferredLanguages = showNonPreferredLanguages;
    [self reloadDataSections];
}

- (MWKLanguageFilter *)languageFilter {
    if (!_languageFilter) {
        _languageFilter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:MWKDataStore.shared.languageLinkController];
    }
    return _languageFilter;
}

#pragma mark - Cell Specialization

- (void)configurePreferredLanguageCell:(WMFLanguageCell *)cell atRow:(NSUInteger)row {
    cell.isPreferred = YES;
    [self configureCell:cell forLangLink:self.languageFilter.filteredPreferredLanguages[row]];
}

- (void)configureAllLanguagesLanguageCell:(WMFLanguageCell *)cell atRow:(NSUInteger)row {
    cell.isPreferred = NO;
    BOOL isPreferredLanguage = [self isFilteredPreferredLanguage:self.languageFilter.filteredLanguages[row]];
    cell.accessoryType = isPreferredLanguage ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    [self configureCell:cell forLangLink:self.languageFilter.filteredLanguages[row]];
}

- (void)configureOtherLanguageCell:(WMFLanguageCell *)cell atRow:(NSUInteger)row {
    cell.isPreferred = NO;
    [self configureCell:cell forLangLink:self.languageFilter.filteredOtherLanguages[row]];
}

- (void)configureCell:(WMFLanguageCell *)cell forLangLink:(MWKLanguageLink *)langLink {
    cell.localizedLanguageName = langLink.localizedName;
    cell.languageName = langLink.name;
    cell.articleTitle = langLink.pageTitleText;
    cell.languageID = langLink.languageCode;
    [cell applyTheme:self.theme];
}

- (void)configureExploreFeedCustomizationCell:(WMFSettingsTableViewCell *)cell {
    cell.disclosureType = WMFSettingsMenuItemDisclosureType_ViewController;
    cell.title = [WMFCommonStrings customizeExploreFeedTitle];
    cell.iconName = nil;
    [cell applyTheme:self.theme];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = 0;
    if (self.showAllLanguages) {
        count++;
    }
    if (self.showPreferredLanguages) {
        count++;
    }
    if (self.showNonPreferredLanguages) {
        count++;
    }
    if (self.showExploreFeedCustomizationSettings) {
        count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isPreferredSection:section]) {
        return self.languageFilter.filteredPreferredLanguages.count;
    } else if ([self isAllLanguagesSection:section]) {
        return self.languageFilter.filteredLanguages.count;
    } else if (self.showExploreFeedCustomizationSettings && [self isExploreFeedCustomizationSettingsSection:section]) {
        return 1;
    } else {
        return self.languageFilter.filteredOtherLanguages.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFLanguageCell *cell =
        (id)[tableView dequeueReusableCellWithIdentifier:[WMFLanguageCell wmf_nibName]
                                            forIndexPath:indexPath];
    if ([self isPreferredSection:indexPath.section]) {
        [self configurePreferredLanguageCell:cell atRow:indexPath.row];
    } else if ([self isAllLanguagesSection:indexPath.section]) {
        [self configureAllLanguagesLanguageCell:cell atRow:indexPath.row];
    } else if (self.showExploreFeedCustomizationSettings && [self isExploreFeedCustomizationSettingsSection:indexPath.section]) {
        WMFSettingsTableViewCell *cell = (WMFSettingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:WMFSettingsTableViewCell.identifier forIndexPath:indexPath];
        [self configureExploreFeedCustomizationCell:cell];
        return cell;
    } else {
        [self configureOtherLanguageCell:cell atRow:indexPath.row];
    }
    return cell;
}

- (CGFloat)alphaForDeleteButton {
    return !self.tableView.editing || (MWKDataStore.shared.languageLinkController.preferredLanguages.count == 1) ? 0.f : 1.f;
}

- (MWKLanguageLink *)languageAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        return self.languageFilter.filteredPreferredLanguages[indexPath.row];
    } else if ([self isAllLanguagesSection:indexPath.section]) {
        return self.languageFilter.filteredLanguages[indexPath.row];
    } else {
        return self.languageFilter.filteredOtherLanguages[indexPath.row];
    }
}

#pragma mark - UITableViewDelegate

- (BOOL)shouldShowHeaderForSection:(NSInteger)section {
    if ([self isAllLanguagesSection:section]) {
        return NO;
    }
    return ([self tableView:self.tableView numberOfRowsInSection:section] > 0);
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (self.showExploreFeedCustomizationSettings && [self isExploreFeedCustomizationSettingsSection:section]) {
        title = WMFLocalizedStringWithDefaultValue(@"explore-feed-language-settings", nil, nil, @"Explore feed language settings", @"Title for Explore feed language settings.");
    } else if ([self isPreferredSection:section]) {
        title = WMFLocalizedStringWithDefaultValue(@"article-languages-yours", nil, nil, @"Your languages", @"Title for list of user's preferred languages");
    } else {
        title = WMFLocalizedStringWithDefaultValue(@"article-languages-others", nil, nil, @"Other languages", @"Title for list of languages not in user's preferred languages");
    }
    return [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (void)configureHeader:(WMFArticleLanguagesSectionHeader *)header forSection:(NSInteger)section {
    header.title = [self titleForHeaderInSection:section];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self shouldShowHeaderForSection:section]) {
        WMFArticleLanguagesSectionHeader *header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];
        [header applyTheme:self.theme];
        [self configureHeader:header forSection:section];
        return header;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self shouldShowHeaderForSection:section] ? WMFLanguageHeaderHeight : 0;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.showAllLanguages && [self isFilteredPreferredLanguage:self.languageFilter.filteredLanguages[indexPath.row]]) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MWKLanguageLink *selectedLanguage = [self languageAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(languagesController:didSelectLanguage:)] && selectedLanguage) {
        [self.delegate languagesController:self didSelectLanguage:selectedLanguage];
    } else if (self.showExploreFeedCustomizationSettings && [self isExploreFeedCustomizationSettingsSection:indexPath.section]) {
        self.title = nil;
        WMFExploreFeedSettingsViewController *feedSettingsVC = [[WMFExploreFeedSettingsViewController alloc] init];
        feedSettingsVC.dataStore = MWKDataStore.shared;
        [feedSettingsVC applyTheme:self.theme];
        [self.navigationController pushViewController:feedSettingsVC animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        if ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1) {
            return UITableViewCellEditingStyleDelete;
        } else {
            return UITableViewCellEditingStyleNone;
        }
    } else if ([self isExploreFeedCustomizationSettingsSection:indexPath.section]) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleInsert: {
            MWKLanguageLink *langLink = self.languageFilter.filteredOtherLanguages[indexPath.row];
            [MWKDataStore.shared.languageLinkController appendPreferredLanguage:langLink];
        } break;
        case UITableViewCellEditingStyleDelete: {
            MWKLanguageLink *langLink = self.languageFilter.filteredPreferredLanguages[indexPath.row];
            [MWKDataStore.shared.languageLinkController removePreferredLanguage:langLink];
        } break;
        case UITableViewCellEditingStyleNone:
            break;
    }
    self.languageFilter.languageFilter = @"";
    self.languageFilterField.text = @"";
    [tableView reloadData];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UITextFieldDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.languageFilter.languageFilter = searchText;
    [self reloadDataSections];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UIAccessibilityAction

- (BOOL)accessibilityPerformEscape {
    [self dismissViewControllerAnimated:YES completion:self.userDismissalCompletionBlock];
    return true;
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.overrideUserInterfaceStyle = theme.isDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    self.view.backgroundColor = theme.colors.baseBackground;
    UIColor *backgroundColor = theme.colors.baseBackground;
    self.tableView.backgroundColor = backgroundColor;
    self.languageFilterField.searchBarStyle = UISearchBarStyleMinimal;
    self.languageFilterField.barTintColor = backgroundColor;
    [self.tableView reloadData];
}

@end

@interface WMFPreferredLanguagesViewController () <WMFLanguagesViewControllerDelegate>

@end

@interface WMFPreferredLanguagesViewController () <WMFAddLanguageDelegate>

@end

@implementation WMFPreferredLanguagesViewController

@dynamic delegate;

+ (instancetype)preferredLanguagesViewController {
    WMFPreferredLanguagesViewController *languagesVC = [[WMFPreferredLanguagesViewController alloc] initWithNibName:@"WMFLanguagesViewController" bundle:nil];
    NSParameterAssert(languagesVC);

    languagesVC.title = [WMFCommonStrings wikipediaLanguages];

    languagesVC.hideLanguageFilter = YES;
    languagesVC.showNonPreferredLanguages = NO;
    languagesVC.disableSelection = NO;

    return languagesVC;
}

- (void)reloadDataSections {
    [super reloadDataSections];
    self.navigationItem.rightBarButtonItem = MWKDataStore.shared.languageLinkController.preferredLanguages.count > 1 ? self.editButtonItem : nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //need to update the footer
    [self setEditing:self.editing animated:NO];

    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 50.f;

    [self.tableView registerNib:[WMFArticleLanguagesSectionFooter wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFArticleLanguagesSectionFooter wmf_nibName]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = [WMFCommonStrings wikipediaLanguages];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (animated) {
        [UIView animateWithDuration:0.30
                         animations:^{
                             self.tableView.tableFooterView.alpha = editing ? 1.0 : 0.0;
                         }];
    } else {
        self.tableView.tableFooterView.alpha = editing ? 1.0 : 0.0;
    }
}

- (void)addLanguageButtonTapped {
    WMFLanguagesViewController *languagesVC = [WMFLanguagesViewController allLanguagesViewController];
    languagesVC.delegate = self;
    [languagesVC applyTheme:self.theme];
    [self presentViewController:[[WMFThemeableNavigationController alloc] initWithRootViewController:languagesVC theme:self.theme style:WMFThemeableNavigationControllerStyleSheet] animated:YES completion:NULL];
}

- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language {
    [MWKDataStore.shared.languageLinkController appendPreferredLanguage:language];
    [self reloadDataSections];
    [controller dismissViewControllerAnimated:YES completion:NULL];
    [self notifyDelegateThatPreferredLanguagesDidUpdate];
}

- (void)notifyDelegateThatPreferredLanguagesDidUpdate {
    if ([self.delegate respondsToSelector:@selector(languagesController:didUpdatePreferredLanguages:)]) {
        [self.delegate languagesController:self didUpdatePreferredLanguages:MWKDataStore.shared.languageLinkController.preferredLanguages];
    }
}

- (BOOL)shouldShowFooterForSection:(NSInteger)section {
    return (self.showPreferredLanguages && (section == 0)) || [self isExploreFeedCustomizationSettingsSection:section];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self shouldShowFooterForSection:section]) {
        WMFArticleLanguagesSectionFooter *footer = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFArticleLanguagesSectionFooter wmf_nibName]];
        NSString *title;
        if ([self isExploreFeedCustomizationSettingsSection:section]) {
            title = WMFLocalizedStringWithDefaultValue(@"settings-languages-feed-customization", nil, nil, @"You can manage which languages are shown on your Explore feed by customizing your Explore feed settings.", @"Explanation of how you can manage which languages appear in the feed.");
            [footer setButtonHidden:YES];
        } else {
            title = WMFLocalizedStringWithDefaultValue(@"settings-primary-language-details", nil, nil, @"The first language in this list is used as the primary language for the app.", @"Explanation of how the first preferred language is used. \"Explore\" is {{msg-wm|Wikipedia-ios-home-title}}.");
            [footer setButtonHidden:NO];
        }
        footer.title = title;
        footer.delegate = self;
        [footer applyTheme:self.theme];
        return footer;
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[WMFLanguageCell class]]) {
        WMFLanguageCell *languageCell = (WMFLanguageCell *)cell;
        languageCell.isPrimary = (indexPath.row == 0) ? YES : NO;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return MWKDataStore.shared.languageLinkController.preferredLanguages.count > 1;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    MWKLanguageLink *langLink = MWKDataStore.shared.languageLinkController.preferredLanguages[sourceIndexPath.row];
    [MWKDataStore.shared.languageLinkController reorderPreferredLanguage:langLink toIndex:destinationIndexPath.row];

    // TODO: reloadData is a bit brute force, but had issues with the "PRIMARY" indicator
    // showing on more than one cell after re-ordering first cell.
    [tableView reloadData];

    [self notifyDelegateThatPreferredLanguagesDidUpdate];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
    [self notifyDelegateThatPreferredLanguagesDidUpdate];
    if (MWKDataStore.shared.languageLinkController.preferredLanguages.count == 1) {
        [self setEditing:NO animated:YES];
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return
        [self isPreferredSection:indexPath.section] &&
        ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1) &&
        (self.languageFilter.languageFilter.length == 0);
}

@end

@interface WMFArticleLanguagesViewController ()

@property (nonatomic, strong) MWKTitleLanguageController *titleLanguageController;
@property (nonatomic, strong, readonly) NSURL *articleURL;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation WMFArticleLanguagesViewController

+ (instancetype)articleLanguagesViewControllerWithArticleURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);

    WMFArticleLanguagesViewController *languagesVC = [[WMFArticleLanguagesViewController alloc] initWithNibName:@"WMFLanguagesViewController" bundle:nil];
    NSParameterAssert(languagesVC);

    languagesVC.articleURL = url;
    languagesVC.editing = NO;
    languagesVC.showExploreFeedCustomizationSettings = NO;
    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"languages-title", nil, nil, @"Change language", @"Title for language picker {{Identical|Language}}");

    return languagesVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setActivityIndicatorVisible:YES];

    self.hideLanguageFilter = YES;
}

- (void)setActivityIndicatorVisible:(BOOL)visible {
    if (visible) {
        if (_activityIndicator == nil) {
            _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            _activityIndicator.color = self.theme.colors.primaryText;
            [self.view wmf_addSubviewWithConstraintsToEdges:_activityIndicator];
            [_activityIndicator startAnimating];
        } else {
            [_activityIndicator startAnimating];
        }
    } else {
        [_activityIndicator stopAnimating];
    }
}

#pragma mark - Getters & Setters

- (void)setArticleURL:(NSURL *)articleURL {
    NSAssert(self.isViewLoaded == NO, @"Article Title must be set prior to view being loaded");
    _articleURL = articleURL;
}

- (MWKTitleLanguageController *)titleLanguageController {
    NSAssert(self.articleURL != nil, @"Article Title must be set before accessing titleLanguageController");
    if (!_titleLanguageController) {
        _titleLanguageController = [[MWKTitleLanguageController alloc] initWithArticleURL:self.articleURL languageController:MWKDataStore.shared.languageLinkController];
    }
    return _titleLanguageController;
}

- (void)loadLanguages {
    [self downloadArticlelanguages];
}

- (MWKLanguageFilter *)languageFilter {
    if (!_languageFilter) {
        _languageFilter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:self.titleLanguageController];
    }
    return _languageFilter;
}

- (void)downloadArticlelanguages {
    @weakify(self);
    [self.titleLanguageController
        fetchLanguagesWithSuccess:^{
            @strongify(self)
                [self setActivityIndicatorVisible:NO];
            if (self.titleLanguageController.allLanguages.count == 0) {
                [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoOtherArticleLanguages theme:self.theme frame:self.view.bounds];
                [self.wmf_emptyView setAlpha:0];
                [UIView animateWithDuration:WMFActivityCompletionAnimationDuration
                                 animations:^{
                                     [self.wmf_emptyView setAlpha:1];
                                 }];
            } else {
                [self wmf_hideEmptyView];
                self.hideLanguageFilter = NO;
            }
            [self reloadDataSections];
        }
        failure:^(NSError *__nonnull error) {
            [self setActivityIndicatorVisible:NO];
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
        }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // HAX: hide line separators which appear before sections/rows load
    return 0.1f;
}

@end
