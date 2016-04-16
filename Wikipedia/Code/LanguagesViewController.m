
#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageFilter.h"
#import "MWKTitleLanguageController.h"
#import "LanguageCell.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "UIView+ConstraintsScale.h"
#import "UIColor+WMFStyle.h"
#import "MWKLanguageLink.h"
#import "UIView+WMFDefaultNib.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <BlocksKit/BlocksKit.h>
#import <Masonry/Masonry.h>
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "WMFArticleLanguagesSectionHeader.h"

static CGFloat const WMFOtherLanguageRowHeight = 138.f;
static CGFloat const WMFLanguageHeaderHeight = 57.f;

@interface LanguagesViewController ()
<UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar* languageFilterField;
@property (strong, nonatomic) MWKLanguageFilter* languageFilter;
@property (strong, nonatomic) MWKTitleLanguageController* titleLanguageController;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* languageFilterTopSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* filterDividerHeightConstraint;

@end

@implementation LanguagesViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _showNonPreferredLanguges = YES;
        _showPreferredLanguges    = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _showNonPreferredLanguges = YES;
        _showPreferredLanguges    = YES;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.tableView.backgroundColor = [UIColor wmf_settingsBackgroundColor];

    self.tableView.estimatedRowHeight = WMFOtherLanguageRowHeight;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    // remove a 1px black border around the search field
    self.languageFilterField.layer.borderColor = [[UIColor wmf_settingsBackgroundColor] CGColor];
    self.languageFilterField.layer.borderWidth = 1.f;

    // stylize
    if ([self.languageFilterField respondsToSelector:@selector(setReturnKeyType:)]) {
        [self.languageFilterField setReturnKeyType:UIReturnKeyDone];
    }
    self.languageFilterField.barTintColor = [UIColor wmf_settingsBackgroundColor];
    self.languageFilterField.placeholder  = MWLocalizedString(@"article-languages-filter-placeholder", nil);

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.filterDividerHeightConstraint.constant = 0.5f;

    [self.tableView registerNib:[WMFArticleLanguagesSectionHeader wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];

    self.tableView.editing = (self.articleTitle == nil);
    
    self.title = self.tableView.editing ? MWLocalizedString(@"settings-my-languages", nil) : MWLocalizedString(@"languages-title", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadLanguages];
}

#pragma mark - Language Loading

- (void)loadLanguages {
    if (self.articleTitle) {
        [self downloadArticlelanguages];
    } else {
        [self reloadDataSections];
    }
}

- (void)downloadArticlelanguages {
    @weakify(self);
    [self.titleLanguageController
     fetchLanguagesWithSuccess:^{
        @strongify(self)
        [self reloadDataSections];
    } failure:^(NSError* __nonnull error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
    }];
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
    if (self.showPreferredLanguges) {
        if (section == 0) {
            return YES;
        }
    }
    return NO;
}

- (void)setShowPreferredLanguges:(BOOL)showPreferredLanguges {
    if (_showPreferredLanguges == showPreferredLanguges) {
        return;
    }
    _showPreferredLanguges = showPreferredLanguges;
    [self reloadDataSections];
}

- (void)setShowNonPreferredLanguges:(BOOL)showNonPreferredLanguges {
    if (_showNonPreferredLanguges == showNonPreferredLanguges) {
        return;
    }
    _showNonPreferredLanguges = showNonPreferredLanguges;
    [self reloadDataSections];
}

#pragma mark - Getters & Setters

- (void)setArticleTitle:(MWKTitle*)articleTitle {
    NSAssert(self.isViewLoaded == NO, @"Article Title must be set prior to view being loaded");
    _articleTitle = articleTitle;
}

- (MWKTitleLanguageController*)titleLanguageController {
    NSAssert(self.articleTitle != nil, @"Article Title must be set before accessing titleLanguageController");
    if (!_titleLanguageController) {
        _titleLanguageController = [[MWKTitleLanguageController alloc] initWithTitle:self.articleTitle languageController:[MWKLanguageLinkController sharedInstance]];
    }
    return _titleLanguageController;
}

- (MWKLanguageFilter*)languageFilter {
    if (!_languageFilter) {
        if (self.articleTitle) {
            _languageFilter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:self.titleLanguageController];
        } else {
            _languageFilter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:[MWKLanguageLinkController sharedInstance]];
        }
    }
    return _languageFilter;
}

#pragma mark - Cell Specialization

- (void)configurePreferredLanguageCell:(LanguageCell*)cell atRow:(NSUInteger)row {
    cell.isPreferred = YES;
    [self configureCell:cell forLangLink:self.languageFilter.filteredPreferredLanguages[row]];
}

- (void)configureOtherLanguageCell:(LanguageCell*)cell atRow:(NSUInteger)row {
    cell.isPreferred = NO;
    [self configureCell:cell forLangLink:self.languageFilter.filteredOtherLanguages[row]];
}

- (void)configureCell:(LanguageCell*)cell forLangLink:(MWKLanguageLink*)langLink {
    cell.localizedLanguageName = langLink.localizedName;
    cell.languageName          = langLink.name;
    cell.articleTitle          = langLink.pageTitleText;
    cell.languageCode          = [self stringForLanguageCode:langLink.languageCode];
    cell.languageID            = langLink.languageCode;
}

- (NSString*)stringForLanguageCode:(NSString*)code {
    return [NSString stringWithFormat:@"%@.%@", code, WMFDefaultSiteDomain];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    NSInteger count = 0;
    if (self.showPreferredLanguges) {
        count++;
    }
    if (self.showNonPreferredLanguges) {
        count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isPreferredSection:section]) {
        return self.languageFilter.filteredPreferredLanguages.count;
    } else {
        return self.languageFilter.filteredOtherLanguages.count;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell =
        [tableView dequeueReusableCellWithIdentifier:[LanguageCell wmf_nibName]
                                        forIndexPath:indexPath];
    if ([self isPreferredSection:indexPath.section]) {
        [self configurePreferredLanguageCell:(LanguageCell*)cell atRow:indexPath.row];
    } else {
        [self configureOtherLanguageCell:(LanguageCell*)cell atRow:indexPath.row];
    }

    return cell;
}

- (MWKLanguageLink*)languageAtIndexPath:(NSIndexPath*)indexPath {
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

- (NSString*)titleForHeaderInSection:(NSInteger)section {
    NSString *title = ([self isPreferredSection:section]) ? MWLocalizedString(@"article-languages-yours", nil) : MWLocalizedString(@"article-languages-others", nil);
    return [title uppercaseStringWithLocale:[NSLocale currentLocale]];;
}

- (void)configureHeader:(WMFArticleLanguagesSectionHeader*)header forSection:(NSInteger)section {
    header.title = [self titleForHeaderInSection:section];
}

- (nullable UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section; {
    if ([self shouldShowHeaderForSection:section]){
        WMFArticleLanguagesSectionHeader* header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFArticleLanguagesSectionHeader wmf_nibName]];
        [self configureHeader:header forSection:section];
        return header;
    }else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return [self shouldShowHeaderForSection:section] ? WMFLanguageHeaderHeight : 0;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MWKLanguageLink* selectedLanguage = [self languageAtIndexPath:indexPath];
    [self.languageSelectionDelegate languagesController:self didSelectLanguage:selectedLanguage];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        if ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1) {
            return UITableViewCellEditingStyleDelete;
        }else{
            return UITableViewCellEditingStyleNone;
        }
    }else{
        return UITableViewCellEditingStyleInsert;
    }    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return
        [self isPreferredSection:indexPath.section]
        &&
        ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1)
        &&
        (self.languageFilter.languageFilter.length == 0)
    ;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[sourceIndexPath.row];
    [[MWKLanguageLinkController sharedInstance] reorderPreferredLanguage:langLink toIndex:destinationIndexPath.row];
    [self.tableView reloadData];
    
    //HAX: any time a re-order, insert, or delete happens tell the delegate the first preferred language
    // was seletected. Will need to clean this up later.
    [self reportFirstPreferredLanguageToDelegate];
}

-(void)reportFirstPreferredLanguageToDelegate {
    MWKLanguageLink* selectedLanguage = [[MWKLanguageLinkController sharedInstance].preferredLanguages firstObject];
    [self.languageSelectionDelegate languagesController:self didSelectLanguage:selectedLanguage];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleInsert: {
            MWKLanguageLink* langLink = self.languageFilter.filteredOtherLanguages[indexPath.row];
            [[MWKLanguageLinkController sharedInstance] appendPreferredLanguage:langLink];
        }
            break;
        case UITableViewCellEditingStyleDelete: {
            MWKLanguageLink* langLink = self.languageFilter.filteredPreferredLanguages[indexPath.row];
            [[MWKLanguageLinkController sharedInstance] removePreferredLanguage:langLink];
        }
            break;
        case UITableViewCellEditingStyleNone:
            break;
    }
    self.languageFilter.languageFilter = @"";
    self.languageFilterField.text = @"";
    [self reportFirstPreferredLanguageToDelegate];
    [tableView reloadData];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    // HAX: hide line separators which appear before sections/rows load
    return 0.1f;
}

#pragma mark - UITextFieldDelegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    self.languageFilter.languageFilter = searchText;
    [self reloadDataSections];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UIAccessibilityAction

- (BOOL)accessibilityPerformEscape {
    [self dismissViewControllerAnimated:YES completion:nil];
    return true;
}

- (NSString*)analyticsContentType {
    return @"Language";
}

@end
