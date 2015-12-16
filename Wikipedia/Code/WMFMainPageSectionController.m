
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"


#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

#import "WMFMainPageTableViewCell.h"
#import "WMFMainPagePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFMainPageSectionIdentifier = @"WMFMainPageSectionIdentifier";

@interface WMFMainPageSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) MWKSiteInfoFetcher* siteInfoFetcher;

@property (nonatomic, strong) MWKSiteInfo* siteInfo;

@end

@implementation WMFMainPageSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    self = [super init];
    if (self) {
        self.site          = site;
        self.savedPageList = savedPageList;
        [self fetchData];
    }
    return self;
}

#pragma mark - Accessors

- (MWKSiteInfoFetcher*)siteInfoFetcher {
    if (_siteInfoFetcher == nil) {
        _siteInfoFetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _siteInfoFetcher;
}

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return dateFormatter;
}

#pragma mark - HomeSectionController

- (id)sectionIdentifier {
    return WMFMainPageSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"home-main-page-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}];
}

- (NSArray*)items {
    if (self.siteInfo) {
        return @[self.siteInfo];
    } else {
        return @[@1];
    }
}

- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [self.siteInfo mainPageTitle];
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFMainPageTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFMainPageTableViewCell identifier]];
    [tableView registerNib:[WMFMainPagePlaceholderTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFMainPagePlaceholderTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if (self.siteInfo) {
        return [WMFMainPageTableViewCell cellForTableView:tableView];
    } else {
        return [WMFMainPagePlaceholderTableViewCell cellForTableView:tableView];
    }
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFMainPageTableViewCell class]]) {
        WMFMainPageTableViewCell* mainPageCell = (id)cell;
        mainPageCell.mainPageTitle.text = self.siteInfo.mainPageTitleText;
        [mainPageCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.siteInfo != nil;
}

#pragma mark - Fetching

- (void)fetchData {
    if (self.siteInfoFetcher.isFetching) {
        DDLogInfo(@"Fetch is already pending, skipping redundant call.");
        return;
    }

    @weakify(self);
    [self.siteInfoFetcher fetchSiteInfoForSite:self.site].then(^(MWKSiteInfo* data) {
        @strongify(self);
        self.siteInfo = data;
        [self.delegate controller:self didSetItems:self.items];
    }).catch(^(NSError* error){
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
    });
}

- (NSString*)analyticsName {
    return @"Main Page";
}

@end

NS_ASSUME_NONNULL_END
