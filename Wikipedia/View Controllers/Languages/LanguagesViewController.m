//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"
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

static CGFloat const LanguagesSectionFooterHeight = 10.f;

static CGFloat const PreferredLanguageRowHeight = 75.f;
static CGFloat const PreferredLanguageFontSize  = 22.f;
static CGFloat const PreferredTitleFontSize     = 17.f;

static CGFloat const OtherLanguageRowHeight = 60.f;
static CGFloat const OtherLanguageFontSize  = 17.f;
static CGFloat const OtherTitleFontSize     = 12.f;

// This assumes the language cell is configured in IB by LanguagesViewController
static NSString* const LangaugesSectionFooterReuseIdentifier = @"LanguagesSectionSeparator";

typedef NS_ENUM (NSUInteger, LanguagesTableSection) {
    PreferredLanguagesSection,
    OtherLanguagesSection,
    LanguagesTableSectionCount
};

@interface LanguagesViewController ()
<UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar* languageFilterField;
@property (readonly, strong, nonatomic) MWKLanguageLinkController* langLinkController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* languageFilterTopSpaceConstraint;

@end

@implementation LanguagesViewController
@synthesize langLinkController = _langLinkController;

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
    if (self.articleTitle) {
        [self downloadArticlelanguages];
    } else {
        [self loadStaticLanguages];
    }
}

#pragma mark - Language Loading

- (void)loadStaticLanguages {
    [self.langLinkController loadStaticSiteLanguageData];
    [self reloadDataSections];
}

- (void)downloadArticlelanguages {
    [self showAlert:MWLocalizedString(@"article-languages-downloading", nil) type:ALERT_TYPE_TOP duration:-1];
    // (temporarily?) hide search field while loading languages since the default alert UI covers the search field
    [self setLanguageFilterHidden:YES animated:NO];

    @weakify(self);
    [self.langLinkController
     loadLanguagesForTitle:self.articleTitle
                   success:^{
        @strongify(self)
        [self fadeAlert];
        [self setLanguageFilterHidden:NO animated:YES];
        [self reloadDataSections];
    }
                   failure:^(NSError* __nonnull error) {
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

#pragma mark - Filtering

- (void)reloadDataSections {
    [self fadeAlert];
    NSMutableIndexSet* dataSections = [NSMutableIndexSet new];
    [dataSections addIndex:PreferredLanguagesSection];
    [dataSections addIndex:OtherLanguagesSection];
    [self.tableView reloadSections:dataSections withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Getters & Setters

- (MWKLanguageLinkController*)langLinkController {
    if (!_langLinkController) {
        _langLinkController = [MWKLanguageLinkController new];
    }
    return _langLinkController;
}

#pragma mark - Cell Specialization

- (void)configurePreferredLanguageCell:(LanguageCell*)languageCell atRow:(NSUInteger)row {
    MWKLanguageLink* langLink = self.langLinkController.filteredPreferredLanguages[row];
    languageCell.languageLabel.font = [UIFont systemFontOfSize:PreferredLanguageFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.titleLabel.font    = [UIFont systemFontOfSize:PreferredTitleFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.languageLabel.text = langLink.name;
    languageCell.titleLabel.text    = langLink.pageTitleText;
}

- (void)configureOtherLanguageCell:(LanguageCell*)languageCell atRow:(NSUInteger)row {
    MWKLanguageLink* langLink = self.langLinkController.filteredOtherLanguages[row];
    languageCell.languageLabel.font = [UIFont systemFontOfSize:OtherLanguageFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.titleLabel.font    = [UIFont systemFontOfSize:OtherTitleFontSize * MENUS_SCALE_MULTIPLIER];
    languageCell.languageLabel.text = langLink.name;
    languageCell.titleLabel.text    = langLink.pageTitleText;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return LanguagesTableSectionCount;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (PreferredLanguagesSection == section) {
        return self.langLinkController.filteredPreferredLanguages.count;
    } else {
        return self.langLinkController.filteredOtherLanguages.count;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell =
        [tableView dequeueReusableCellWithIdentifier:[LanguageCell wmf_nibName]
                                        forIndexPath:indexPath];
    if (indexPath.section == PreferredLanguagesSection) {
        [self configurePreferredLanguageCell:(LanguageCell*)cell atRow:indexPath.row];
    } else {
        [self configureOtherLanguageCell:(LanguageCell*)cell atRow:indexPath.row];
    }
    return cell;
}

- (MWKLanguageLink*)languageAtIndexPath:(NSIndexPath*)indexPath {
    if (PreferredLanguagesSection == indexPath.section) {
        return self.langLinkController.filteredPreferredLanguages[indexPath.row];
    } else {
        return self.langLinkController.filteredOtherLanguages[indexPath.row];
    }
}

#pragma mark - UITableViewDelegate

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
#warning heightForRowAtIndexPath: is not necessary in iOS 8, since it will rely on the cell's intrinsic content size
#endif
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (PreferredLanguagesSection == indexPath.section) {
        return PreferredLanguageRowHeight * MENUS_SCALE_MULTIPLIER;
    } else {
        return OtherLanguageRowHeight * MENUS_SCALE_MULTIPLIER;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    if (section == PreferredLanguagesSection && self.langLinkController.filteredPreferredLanguages.count > 0) {
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
    [self.langLinkController saveSelectedLanguage:selectedLanguage];
    [self.languageSelectionDelegate languageSelected:selectedLanguage sender:self];
}

#pragma mark - UITextFieldDelegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    self.langLinkController.languageFilter = searchText;
    [self reloadDataSections];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [searchBar resignFirstResponder];
}

@end
