#import "WMFLanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageFilter.h"
#import "MWKTitleLanguageController.h"
#import "WMFLanguageCell.h"
#import "UIColor+WMFStyle.h"
#import "MWKLanguageLink.h"
#import "UIView+WMFDefaultNib.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"
#import "WMFArticleLanguagesSectionHeader.h"
#import "WMFArticleLanguagesSectionFooter.h"
#import "UIViewController+WMFStoryboardUtilities.h"

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

@property (nonatomic, assign) BOOL showPreferredLanguages;
@property (nonatomic, assign) BOOL showNonPreferredLanguages;

@end

@implementation WMFLanguagesViewController {
  @public
    MWKLanguageFilter *_languageFilter;
}

@synthesize languageFilter = _languageFilter;

+ (instancetype)languagesViewController {
    WMFLanguagesViewController *languagesVC = [WMFLanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    NSParameterAssert(languagesVC);

    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"article-languages-label", nil, nil, @"Choose language", @"Header label for per-article language selector screen.\n{{Identical|Choose language}}");
    languagesVC.editing = NO;
    return languagesVC;
}

+ (instancetype)nonPreferredLanguagesViewController {
    WMFLanguagesViewController *languagesVC = [WMFLanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    NSParameterAssert(languagesVC);

    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"settings-my-languages", nil, nil, @"My languages", @"Title for list of user's preferred languages");
    languagesVC.editing = NO;
    languagesVC.showPreferredLanguages = NO;

    return languagesVC;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showNonPreferredLanguages = YES;
        _showPreferredLanguages = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _showNonPreferredLanguages = YES;
        _showPreferredLanguages = YES;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.title, @"Don't forget to set a title!");

    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.tableView.backgroundColor = [UIColor wmf_settingsBackground];

    self.tableView.estimatedRowHeight = WMFOtherLanguageRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    // remove a 1px black border around the search field
    self.languageFilterField.layer.borderColor = [[UIColor wmf_settingsBackground] CGColor];
    self.languageFilterField.layer.borderWidth = 1.f;

    // stylize
    if ([self.languageFilterField respondsToSelector:@selector(setReturnKeyType:)]) {
        [self.languageFilterField setReturnKeyType:UIReturnKeyDone];
    }
    self.languageFilterField.barTintColor = [UIColor wmf_settingsBackground];
    self.languageFilterField.placeholder = WMFLocalizedStringWithDefaultValue(@"article-languages-filter-placeholder", nil, nil, @"Find language", @"Filter languages text box placeholder text.");

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.filterDividerHeightConstraint.constant = 0.5f;

    [self.tableView registerNib:[WMFLanguageCell wmf_classNib] forCellReuseIdentifier:[WMFLanguageCell wmf_nibName]];
    [self.tableView registerNib:[WMFArticleLanguagesSectionHeader wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];

    //HAX: force these to take effect if they were set before the VC was presented/pushed.
    self.editing = self.editing;
    self.hideLanguageFilter = self.hideLanguageFilter;
    self.disableSelection = self.disableSelection;
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (BOOL)isPreferredSection:(NSInteger)section {
    if (self.showPreferredLanguages) {
        if (section == 0) {
            return YES;
        }
    }
    return NO;
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
        _languageFilter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:[MWKLanguageLinkController sharedInstance]];
    }
    return _languageFilter;
}

#pragma mark - Cell Specialization

- (void)configurePreferredLanguageCell:(WMFLanguageCell *)cell atRow:(NSUInteger)row {
    cell.isPreferred = YES;
    [self configureCell:cell forLangLink:self.languageFilter.filteredPreferredLanguages[row]];
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
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = 0;
    if (self.showPreferredLanguages) {
        count++;
    }
    if (self.showNonPreferredLanguages) {
        count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isPreferredSection:section]) {
        return self.languageFilter.filteredPreferredLanguages.count;
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
    } else {
        [self configureOtherLanguageCell:cell atRow:indexPath.row];
    }

    cell.deleteButton.alpha = [self alphaForDeleteButton];

    return cell;
}

- (CGFloat)alphaForDeleteButton {
    return !self.tableView.editing || ([MWKLanguageLinkController sharedInstance].preferredLanguages.count == 1) ? 0.f : 1.f;
}

- (void)updateDeleteButtonsVisibility {
    for (WMFWelcomeLanguageTableViewCell *cell in self.tableView.visibleCells) {
        cell.deleteButton.alpha = [self alphaForDeleteButton];
    }
}

- (MWKLanguageLink *)languageAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        return self.languageFilter.filteredPreferredLanguages[indexPath.row];
    } else {
        return self.languageFilter.filteredOtherLanguages[indexPath.row];
    }
}

#pragma mark - UITableViewDelegate

- (BOOL)shouldShowHeaderForSection:(NSInteger)section {
    return ([self tableView:self.tableView numberOfRowsInSection:section] > 0);
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    NSString *title = ([self isPreferredSection:section]) ? WMFLocalizedStringWithDefaultValue(@"article-languages-yours", nil, nil, @"Your languages", @"Title for list of user's preferred languages") : WMFLocalizedStringWithDefaultValue(@"article-languages-others", nil, nil, @"Other languages", @"Title for list of languages not in user's preferred languages");
    return [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (void)configureHeader:(WMFArticleLanguagesSectionHeader *)header forSection:(NSInteger)section {
    header.title = [self titleForHeaderInSection:section];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self shouldShowHeaderForSection:section]) {
        WMFArticleLanguagesSectionHeader *header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];
        [self configureHeader:header forSection:section];
        return header;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self shouldShowHeaderForSection:section] ? WMFLanguageHeaderHeight : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MWKLanguageLink *selectedLanguage = [self languageAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(languagesController:didSelectLanguage:)]) {
        [self.delegate languagesController:self didSelectLanguage:selectedLanguage];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        if ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1) {
            return UITableViewCellEditingStyleDelete;
        } else {
            return UITableViewCellEditingStyleNone;
        }
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
            [[MWKLanguageLinkController sharedInstance] appendPreferredLanguage:langLink];
        } break;
        case UITableViewCellEditingStyleDelete: {
            MWKLanguageLink *langLink = self.languageFilter.filteredPreferredLanguages[indexPath.row];
            [[MWKLanguageLinkController sharedInstance] removePreferredLanguage:langLink];
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
    [self dismissViewControllerAnimated:YES completion:nil];
    return true;
}

- (NSString *)analyticsContentType {
    return @"Language";
}

@end

@interface WMFPreferredLanguagesViewController () <WMFLanguagesViewControllerDelegate>

@end

@implementation WMFPreferredLanguagesViewController

@dynamic delegate;

+ (instancetype)preferredLanguagesViewController {
    WMFPreferredLanguagesViewController *languagesVC = [WMFPreferredLanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    NSParameterAssert(languagesVC);

    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"settings-my-languages", nil, nil, @"My languages", @"Title for list of user's preferred languages");

    languagesVC.hideLanguageFilter = YES;
    languagesVC.showNonPreferredLanguages = NO;
    languagesVC.disableSelection = NO;

    languagesVC.editButtonItem.tintColor = [UIColor wmf_blueTint];
    languagesVC.navigationItem.rightBarButtonItem = languagesVC.editButtonItem;
    return languagesVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //need to update the footer
    [self setEditing:self.editing animated:NO];

    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 50.f;

    [self.tableView registerNib:[WMFArticleLanguagesSectionFooter wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFArticleLanguagesSectionFooter wmf_nibName]];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (animated) {
        [UIView animateWithDuration:0.30
                         animations:^{
                             self.tableView.tableFooterView.alpha = editing ? 1.0 : 0.0;
                             [self updateDeleteButtonsVisibility];
                         }];
    } else {
        self.tableView.tableFooterView.alpha = editing ? 1.0 : 0.0;
        [self updateDeleteButtonsVisibility];
    }
}

- (IBAction)addLanguages:(id)sender {
    WMFLanguagesViewController *languagesVC = [WMFLanguagesViewController nonPreferredLanguagesViewController];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:NULL];
}

- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language {
    [[MWKLanguageLinkController sharedInstance] appendPreferredLanguage:language];
    [self reloadDataSections];
    [controller dismissViewControllerAnimated:YES completion:NULL];
    [self notifyDelegateThatPreferredLanguagesDidUpdate];
}

- (void)notifyDelegateThatPreferredLanguagesDidUpdate {
    if ([self.delegate respondsToSelector:@selector(languagesController:didUpdatePreferredLanguages:)]) {
        [self.delegate languagesController:self didUpdatePreferredLanguages:[MWKLanguageLinkController sharedInstance].preferredLanguages];
    }
}

- (BOOL)shouldShowFooterForSection:(NSInteger)section {
    return (self.showPreferredLanguages && (section == 0));
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self shouldShowFooterForSection:section]) {
        WMFArticleLanguagesSectionFooter *footer = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFArticleLanguagesSectionFooter wmf_nibName]];
        footer.title = WMFLocalizedStringWithDefaultValue(@"settings-primary-language-details", nil, nil, @"The first language in this list is used as the primary language for the app. Changing this language will change daily content (such as Featured Article) shown on Explore.", @"Explanation of how the first preferred language is used. \"Explore\" is {{msg-wm|Wikipedia-ios-home-title}}.");
        return footer;
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFLanguageCell *cell = (WMFLanguageCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.isPrimary = (indexPath.row == 0) ? YES : NO;
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    MWKLanguageLink *langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[sourceIndexPath.row];
    [[MWKLanguageLinkController sharedInstance] reorderPreferredLanguage:langLink toIndex:destinationIndexPath.row];

    // TODO: reloadData is a bit brute force, but had issues with the "PRIMARY" indicator
    // showing on more than one cell after re-ordering first cell.
    [tableView reloadData];

    [self notifyDelegateThatPreferredLanguagesDidUpdate];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];

    [self notifyDelegateThatPreferredLanguagesDidUpdate];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return
        [self isPreferredSection:indexPath.section] &&
        ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1) &&
        (self.languageFilter.languageFilter.length == 0);
}

@end

@interface WMFArticleLanguagesViewController ()

@property (strong, nonatomic) MWKTitleLanguageController *titleLanguageController;

@end

@implementation WMFArticleLanguagesViewController

+ (instancetype)articleLanguagesViewControllerWithArticleURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);

    WMFArticleLanguagesViewController *languagesVC = [WMFArticleLanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    NSParameterAssert(languagesVC);

    languagesVC.articleURL = url;
    languagesVC.editing = NO;
    languagesVC.title = WMFLocalizedStringWithDefaultValue(@"languages-title", nil, nil, @"Change language", @"Title for language picker\n{{Identical|Language}}");

    return languagesVC;
}

#pragma mark - Getters & Setters

- (void)setArticleURL:(NSURL *)articleURL {
    NSAssert(self.isViewLoaded == NO, @"Article Title must be set prior to view being loaded");
    _articleURL = articleURL;
}

- (MWKTitleLanguageController *)titleLanguageController {
    NSAssert(self.articleURL != nil, @"Article Title must be set before accessing titleLanguageController");
    if (!_titleLanguageController) {
        _titleLanguageController = [[MWKTitleLanguageController alloc] initWithArticleURL:self.articleURL languageController:[MWKLanguageLinkController sharedInstance]];
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
                [self reloadDataSections];
        }
        failure:^(NSError *__nonnull error) {
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
        }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // HAX: hide line separators which appear before sections/rows load
    return 0.1f;
}

@end
