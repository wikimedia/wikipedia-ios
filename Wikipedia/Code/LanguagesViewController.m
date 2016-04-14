
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

static CGFloat const WMFOtherLanguageRowHeight = 138.f;

@interface LanguagesViewController ()
<UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar* languageFilterField;
@property (strong, nonatomic) MWKLanguageFilter* languageFilter;
@property (strong, nonatomic) MWKTitleLanguageController* titleLanguageController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* languageFilterTopSpaceConstraint;

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

- (NSString*)title {
    return MWLocalizedString(@"languages-title", nil);
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
    [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"article-languages-downloading", nil) sticky:YES dismissPreviousAlerts:NO tapCallBack:NULL];
    // (temporarily?) hide search field while loading languages since the default alert UI covers the search field
    [self setLanguageFilterHidden:YES animated:NO];

    @weakify(self);
    [self.titleLanguageController
     fetchLanguagesWithSuccess:^{
        @strongify(self)
        //This can fire rather quickly, lets give the user a chance to read the message before we dismiss
        dispatchOnMainQueueAfterDelayInSeconds(1.0, ^{
            [[WMFAlertManager sharedInstance] dismissAlert];
        });
        [self setLanguageFilterHidden:NO animated:YES];
        [self reloadDataSections];
    } failure:^(NSError* __nonnull error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
    }];
}

#pragma mark - Search Bar Visibility

- (void)setLanguageFilterHidden:(BOOL)hidden animated:(BOOL)animated {
    dispatch_block_t updateConstraint = ^{
        // iOS7: need to do this w/ an IBOutlet due to some conflict between Masonry & layout guides
        self.languageFilterTopSpaceConstraint.constant = hidden ? -self.languageFilterField.frame.size.height : 0.f;
        [self.languageFilterField layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:[CATransaction animationDuration] animations:updateConstraint];
    } else {
        updateConstraint();
    }
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

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0){
        return nil;
    }else{
        NSString *title = ([self isPreferredSection:section]) ? MWLocalizedString(@"article-languages-yours", nil) : MWLocalizedString(@"article-languages-others", nil);
        return [title uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    // HAX: hide line separators which appear before sections/rows load
    return 0.1f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    view.textLabel.font = [UIFont systemFontOfSize:12];
    view.textLabel.textColor = [UIColor wmf_customGray];
    view.contentView.backgroundColor = [UIColor wmf_settingsBackgroundColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return ([self tableView:tableView numberOfRowsInSection:section] == 0) ? 0 : 56.0;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MWKLanguageLink* selectedLanguage = [self languageAtIndexPath:indexPath];
    [self.languageSelectionDelegate languagesController:self didSelectLanguage:selectedLanguage];
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
