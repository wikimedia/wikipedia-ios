#import "WMFRelatedSectionController.h"

// Networking & Model
#import "WMFRelatedSearchFetcher.h"
#import "MWKTitle.h"
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"
#import "MWKSavedPageList.h"

// Controllers
#import "WMFRelatedTitleListDataSource.h"

// Frameworks
#import "Wikipedia-Swift.h"

// View
#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"

// Style
#import "UIFont+WMFStyle.h"
#import "NSString+FormattedAttributedString.h"

static NSString* const WMFRelatedSectionIdentifierPrefix = @"WMFRelatedSectionIdentifier";
static NSUInteger const WMFRelatedSectionMaxResults      = 3;

@interface WMFRelatedSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) WMFRelatedSearchFetcher* relatedSearchFetcher;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) WMFRelatedTitleListDataSource* relatedTitleDataSource;

@property (nonatomic, strong) WMFRelatedSearchResults* searchResults;

@end

@implementation WMFRelatedSectionController
@synthesize relatedTitleDataSource = _relatedTitleDataSource;

@synthesize delegate = _delegate;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                       savedPageList:(MWKSavedPageList*)savedPageList {
    return [self initWithArticleTitle:title
                        savedPageList:savedPageList
                 relatedSearchFetcher:[[WMFRelatedSearchFetcher alloc] init]];
}

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                       savedPageList:(MWKSavedPageList*)savedPageList
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher {
    NSParameterAssert(title);
    NSParameterAssert(savedPageList);
    NSParameterAssert(relatedSearchFetcher);
    self = [super init];
    if (self) {
        self.relatedSearchFetcher = relatedSearchFetcher;
        self.title                = title;
        self.savedPageList        = savedPageList;
    }
    return self;
}

- (id)sectionIdentifier {
    return [WMFRelatedSectionIdentifierPrefix stringByAppendingString:self.title.text];
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-recent"];
}

- (NSAttributedString*)headerText {
    return
        [MWLocalizedString(@"home-continue-related-heading", nil) attributedStringWithAttributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}
                                                                             substitutionStrings:@[self.title.text]
                                                                          substitutionAttributes:@[@{NSForegroundColorAttributeName: [UIColor wmf_blueTintColor]}]
        ];
}

- (NSString*)footerText {
    return
        [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                    withString:self.title.text];
}

- (NSArray*)items {
    if ([self hasResults]) {
        return [self.searchResults.results
                wmf_safeSubarrayWithRange:NSMakeRange(0, WMFRelatedSectionMaxResults)];
    } else {
        return @[@1, @2, @3];
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    MWKSearchResult* result = self.items[index];
    MWKSite* site           = self.title.site;
    MWKTitle* title         = [site titleWithString:result.displayTitle];
    return title;
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    [tableView registerNib:[WMFArticlePlaceholderTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePlaceholderTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([self hasResults]) {
        return [WMFArticlePreviewTableViewCell cellForTableView:tableView];
    } else {
        return [WMFArticlePlaceholderTableViewCell cellForTableView:tableView];
    }
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewTableViewCell class]]) {
        WMFArticlePreviewTableViewCell* previewCell = (id)cell;
        MWKSearchResult* result                     = object;
        previewCell.titleText       = result.displayTitle;
        previewCell.descriptionText = result.wikidataDescription;
        previewCell.snippetText     = result.extract;
        [previewCell setImageURL:result.thumbnailURL];
        [previewCell setSaveableTitle:[self titleForItemAtIndex:indexPath.row] savedPageList:self.savedPageList];
        [previewCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
        previewCell.saveButtonController.analyticsSource = self;
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return [self hasResults];
}

- (WMFRelatedTitleListDataSource*)relatedTitleDataSource {
    if (!_relatedTitleDataSource) {
        /*
           HAX: Need to use the "more" data source to fetch data and keep it around since morelike: searches for the same
           title don't have the same results in order. might need to look into continuation soon
         */
        _relatedTitleDataSource = [[WMFRelatedTitleListDataSource alloc]
                                   initWithTitle:self.title
                                       dataStore:self.savedPageList.dataStore
                                   savedPageList:self.savedPageList
                                     resultLimit:WMFMaxRelatedSearchResultLimit
                                         fetcher:self.relatedSearchFetcher];
    }
    return _relatedTitleDataSource;
}

- (SSArrayDataSource<WMFTitleListDataSource>*)extendedListDataSource {
    if (!self.relatedSearchFetcher.isFetching && !self.relatedTitleDataSource.relatedSearchResults) {
        [self.relatedTitleDataSource fetch];
    }
    return self.relatedTitleDataSource;
}

- (BOOL)hasResults {
    return self.searchResults && self.searchResults.results && self.searchResults.results.count > 0;
}

#pragma mark - Fetch

- (void)fetchDataIfNeeded {
    if (self.relatedSearchFetcher.isFetching || self.searchResults) {
        return;
    }

    @weakify(self);
    [self.relatedTitleDataSource fetch]
    .then(^(WMFRelatedSearchResults* results){
        @strongify(self);
        self.searchResults = results;
        [self.delegate controller:self didSetItems:self.items];
    })
    .catch(^(NSError* error){
        @strongify(self);
        self.searchResults = nil;
        [self.delegate controller:self didFailToUpdateWithError:error];
        WMF_TECH_DEBT_TODO(show empty view)
        [self.delegate controller : self didSetItems : self.items];
    });
}

- (NSString*)analyticsName {
    return @"Related";
}

@end
