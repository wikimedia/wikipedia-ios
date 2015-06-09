//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguagesViewController.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "LanguageLinksFetcher.h"
#import "QueuesSingleton.h"
#import "LanguagesCell.h"
#import "Defines.h"
#import "WMFAssetsFile.h"
#import "UIViewController+Alert.h"
#import "UIViewController+ModalPop.h"
#import "UIView+ConstraintsScale.h"
#import "NSString+Extras.h"
#import "LanguagesSectionHeaderView.h"
#import "UIView+WMFDefaultNib.h"
#import "LanguagesTableSectionViewModel.h"

#import <BlocksKit/BlocksKit.h>
#import <Masonry/Masonry.h>

#pragma mark - Defines

@interface LanguagesViewController ()

/// Array of dictionaries which represent languages to choose from.
@property (strong, nonatomic) NSArray* languagesData;

/// Array of LanguagesTableSectionViewModel objects.
@property (copy, nonatomic) NSArray* sections;

@property (strong, nonatomic) NSString* filterString;
@property (strong, nonatomic) UITextField* filterTextField;

@end

@implementation LanguagesViewController

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.downloadLanguagesForCurrentArticle = NO;
    }
    return self;
}

- (NavBarMode)navBarMode {
    return NAVBAR_MODE_X_WITH_TEXT_FIELD;
}

- (NSString*)title {
    return MWLocalizedString(@"article-languages-filter-placeholder", nil);
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[LanguagesSectionHeaderView class]
     forHeaderFooterViewReuseIdentifier:[LanguagesSectionHeaderView wmf_nibName]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor     = [UIColor whiteColor];
//    self.tableView.contentInset   = UIEdgeInsetsMake(15.0 * MENUS_SCALE_MULTIPLIER, 0, 0, 0);
    self.filterString = @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.downloadLanguagesForCurrentArticle) {
        [self downloadLangLinkData];
    } else {
        WMFAssetsFile* assetsFile = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeLanguages];
        self.languagesData = assetsFile.array;
        [self reloadTableDataFiltered];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.filterTextField resignFirstResponder];

    [[QueuesSingleton sharedInstance].languageLinksFetcher.operationQueue cancelAllOperations];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"NavItemTapped"
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"NavTextFieldTextChanged"
                                                  object:nil];

    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navItemTappedNotification:)
                                                 name:@"NavItemTapped"
                                               object:nil];

    // Listen for nav text field text changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navTextFieldTextChangedNotification:)
                                                 name:@"NavTextFieldTextChanged"
                                               object:nil];
}

#pragma mark - Top menu

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    UIView* tappedItem     = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModal];

            break;

        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navTextFieldTextChangedNotification:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSString* text         = userInfo[@"text"];

    self.filterString = text;
    [self reloadTableDataFiltered];
}

- (void)reloadTableDataFiltered {
    NSArray* filteredLanguages;
    if (!self.filterString.length) {
        filteredLanguages = [self.languagesData copy];
    } else {
        filteredLanguages = [self.languagesData bk_select:^BOOL (NSDictionary* lang) {
            // TODO: use proper model object and refactor this into an instance method
            return [lang[@"name"] wmf_caseInsensitiveContainsString:self.filterString]
            || [lang[@"canonical_name"] wmf_caseInsensitiveContainsString:self.filterString]
            || [lang[@"code"] wmf_caseInsensitiveContainsString:self.filterString];
        }];
    }

    LanguagesTableSectionViewModel* preferredLanguagesSection =
        [[LanguagesTableSectionViewModel alloc]
         initWithTitle:MWLocalizedString(@"article-languages-preferred-section-header", nil)
             languages:[filteredLanguages bk_select:^BOOL (NSDictionary* lang) {
        return [[NSLocale preferredLanguages] containsObject:lang[@"code"]];
    }]];

    LanguagesTableSectionViewModel* otherLanguagesSection =
        [[LanguagesTableSectionViewModel alloc]
         initWithTitle:MWLocalizedString(@"article-languages-other-section-header", nil)
             languages:[filteredLanguages bk_select:^BOOL (id evaluatedObject) {
        return ![preferredLanguagesSection.languages containsObject:evaluatedObject];
    }]];

    self.sections = [@[preferredLanguagesSection, otherLanguagesSection] bk_select :^BOOL (LanguagesTableSectionViewModel* section) {
        return section.languages.count > 0;
    }];

    [self.tableView reloadData];
}

#pragma mark - Article lang list download op

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[LanguageLinksFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                //[self showAlert:@"Language links loaded."];
                [self fadeAlert];

                self.languagesData = fetchedData;
                [self reloadTableDataFiltered];
            }
            break;

            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;

            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

- (void)downloadLangLinkData {
    [self showAlert:MWLocalizedString(@"article-languages-downloading", nil) type:ALERT_TYPE_TOP duration:-1];
    WMFAssetsFile* assetsFile = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeLanguages];

    [[QueuesSingleton sharedInstance].languageLinksFetcher.operationQueue cancelAllOperations];

    (void)[[LanguageLinksFetcher alloc] initAndFetchLanguageLinksForPageTitle:[SessionSingleton sharedInstance].currentArticle.title
                                                                 allLanguages:assetsFile.array
                                                                  withManager:[QueuesSingleton sharedInstance].languageLinksFetcher
                                                           thenNotifyDelegate:self];
}

- (NSDictionary*)languageAtIndexPath:(NSIndexPath*)indexPath {
    return [self.sections[indexPath.section] languages][indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.sections[section] languages] count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* cellId = @"LanguagesCell";
    LanguagesCell* cell     = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];

    NSDictionary* d = [self languageAtIndexPath:indexPath];

    cell.textLabel.text      = d[@"name"];
    cell.canonicalLabel.text = d[@"canonical_name"];

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return [LanguagesSectionHeaderView defaultHeaderHeight];
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    LanguagesSectionHeaderView* headerView =
        [tableView dequeueReusableHeaderFooterViewWithIdentifier:[LanguagesSectionHeaderView wmf_nibName]];
    headerView.titleLabel.text = [self.sections[section] title];
    return headerView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 48.0 * MENUS_SCALE_MULTIPLIER;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary* selectedLangInfo = [self languageAtIndexPath:indexPath];
    [self.languageSelectionDelegate languageSelected:selectedLangInfo sender:self];
}

@end
