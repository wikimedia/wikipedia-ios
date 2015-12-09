
#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageFilter.h"
#import "MWKTitleLanguageController.h"
#import "LanguageCell.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "UIViewController+Alert.h"
#import "UIView+ConstraintsScale.h"
#import "MWKLanguageLink.h"
#import "UIView+WMFDefaultNib.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <BlocksKit/BlocksKit.h>
#import <Masonry/Masonry.h>
#import "UIView+WMFRTLMirroring.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"

static CGFloat const LanguagesSectionFooterHeight = 10.f;

static CGFloat const PreferredLanguageRowHeight = 75.f;
static CGFloat const PreferredLanguageFontSize  = 22.f;
static CGFloat const PreferredTitleFontSize     = 17.f;

static CGFloat const OtherLanguageRowHeight = 60.f;
static CGFloat const OtherLanguageFontSize  = 17.f;
static CGFloat const OtherTitleFontSize     = 12.f;

// This assumes the language cell is configured in IB by LanguagesViewController
static NSString* const LangaugesSectionFooterReuseIdentifier = @"LanguagesSectionSeparator";

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

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.tableView.backgroundColor = CHROME_COLOR;

    [self.tableView registerClass:[UITableViewHeaderFooterView class]
     forHeaderFooterViewReuseIdentifier:LangaugesSectionFooterReuseIdentifier];

    self.tableView.estimatedRowHeight = OtherLanguageRowHeight * MENUS_SCALE_MULTIPLIER;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    // remove a 1px black border around the search field
    self.languageFilterField.layer.borderColor = [CHROME_COLOR CGColor];
    self.languageFilterField.layer.borderWidth = 1.f;

    // stylize
    if ([self.languageFilterField respondsToSelector:@selector(setReturnKeyType:)]) {
        [self.languageFilterField setReturnKeyType:UIReturnKeyDone];
    }
    self.languageFilterField.barTintColor = CHROME_COLOR;
    self.languageFilterField.placeholder  = MWLocalizedString(@"article-languages-filter-placeholder", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    [[WMFAlertManager sharedInstance] showAlert:[[WMFAlert alloc] initWithType:WMFAlertTypeArticleLanguageDownload] tapCallBack:NULL];
    // (temporarily?) hide search field while loading languages since the default alert UI covers the search field
    [self setLanguageFilterHidden:YES animated:NO];

    @weakify(self);
    [self.titleLanguageController
     fetchLanguagesWithSuccess:^{
        @strongify(self)
        [self fadeAlert];
        [self setLanguageFilterHidden:NO animated:YES];
        [self reloadDataSections];
    } failure:^(NSError* __nonnull error) {
        @strongify(self)
        [self showAlert : error.localizedDescription type : ALERT_TYPE_TOP duration : -1];
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
    [self fadeAlert];
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

- (void)configurePreferredLanguageCell:(LanguageCell*)languageCell atRow:(NSUInteger)row {
    MWKLanguageLink* langLink = self.languageFilter.filteredPreferredLanguages[row];
    languageCell.languageLabel.font = [UIFont systemFontOfSize:PreferredLanguageFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.titleLabel.font    = [UIFont systemFontOfSize:PreferredTitleFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.languageLabel.text = langLink.name;
    languageCell.titleLabel.text    = langLink.pageTitleText;
}

- (void)configureOtherLanguageCell:(LanguageCell*)languageCell atRow:(NSUInteger)row {
    MWKLanguageLink* langLink = self.languageFilter.filteredOtherLanguages[row];
    languageCell.languageLabel.font = [UIFont systemFontOfSize:OtherLanguageFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.titleLabel.font    = [UIFont systemFontOfSize:OtherTitleFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.languageLabel.text = langLink.name;
    languageCell.titleLabel.text    = langLink.pageTitleText;
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

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
#warning heightForRowAtIndexPath: is not necessary in iOS 8, since it will rely on the cell's intrinsic content size
#endif
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([self isPreferredSection:indexPath.section]) {
        return PreferredLanguageRowHeight * MENUS_SCALE_MULTIPLIER;
    } else {
        return OtherLanguageRowHeight * MENUS_SCALE_MULTIPLIER;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    if ([self isPreferredSection:section] && self.languageFilter.filteredPreferredLanguages.count > 0) {
        // collapse footer when empty, removing needless padding of "other" section from top of table
        return LanguagesSectionFooterHeight;
    } else {
        return 0.f;
    }
}

// using footers instead of headers because footers don't "stick"
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    UITableViewHeaderFooterView* footerView =
        [tableView dequeueReusableHeaderFooterViewWithIdentifier:LangaugesSectionFooterReuseIdentifier];
    footerView.contentView.backgroundColor = CHROME_COLOR;
    return footerView;
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

@end
