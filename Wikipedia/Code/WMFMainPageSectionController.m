
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"

#import "MWKDataStore.h"
#import "MWKUserDataStore.h"
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

@property (nonatomic, strong) MWKSiteInfoFetcher* siteInfoFetcher;

@property (nonatomic, strong, nullable) MWKSiteInfo* siteInfo;

@end

@implementation WMFMainPageSectionController

- (instancetype)initWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site = site;
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

- (NSString*)cellIdentifier {
    return [WMFMainPageTableViewCell identifier];
}

- (UINib*)cellNib {
    return [WMFMainPageTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString*)placeholderCellIdentifier {
    return [WMFMainPagePlaceholderTableViewCell identifier];
}

- (nullable UINib*)placeholderCellNib {
    return [WMFMainPagePlaceholderTableViewCell wmf_classNib];
}

- (void)configureCell:(WMFMainPageTableViewCell*)cell withItem:(MWKSiteInfo*)item atIndexPath:(NSIndexPath*)indexPath {
    cell.mainPageTitle.text = item.mainPageTitleText;
    [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
}

- (NSString*)analyticsName {
    return @"Main Page";
}

- (CGFloat)estimatedRowHeight {
    return [WMFMainPageTableViewCell estimatedRowHeight];
}

- (AnyPromise*)fetchData {
    @weakify(self);
    return [self.siteInfoFetcher fetchSiteInfoForSite:self.site].then(^(MWKSiteInfo* data) {
        @strongify(self);
        self.siteInfo = data;
        return @[self.siteInfo];
    }).catch(^(NSError* error){
        @strongify(self);
        self.siteInfo = nil;
        return error;
    });
}

#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.siteInfo mainPageTitle];
}

@end

NS_ASSUME_NONNULL_END
