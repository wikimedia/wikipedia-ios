
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"

#import "MWKSite.h"
#import "MWKSiteInfo.h"

#import "WMFMainPageTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

static NSString* const WMFMainPageSectionIdentifier = @"WMFMainPageSectionIdentifier";

@interface WMFMainPageSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong) MWKSiteInfoFetcher* fetcher;

@property (nonatomic, strong) MWKSiteInfo* siteInfo;

@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@end

@implementation WMFMainPageSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site {
    NSParameterAssert(site);
    self = [super init];
    if (self) {
        self.site = site;
        [self getSiteInfo];
    }
    return self;
}

- (MWKSiteInfoFetcher*)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _fetcher;
}

- (NSDateFormatter*)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter           = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return _dateFormatter;
}

- (id)sectionIdentifier {
    return WMFMainPageSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:[self.dateFormatter stringFromDate:[NSDate date]] attributes:nil];
}

- (NSArray*)items {
    if (self.siteInfo) {
        return @[self.siteInfo];
    } else {
        return nil;
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [self.siteInfo mainPageTitle];
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFMainPageTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFMainPageTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFMainPageTableViewCell cellForTableView:tableView];
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFMainPageTableViewCell class]]) {
        WMFMainPageTableViewCell* mainPageCell = (id)cell;
        mainPageCell.mainPageTitle.text = self.siteInfo.mainPageTitleText;
    }
}

- (void)getSiteInfo {
    if (self.fetcher.isFetching) {
        return;
    }
    @weakify(self);
    [self.fetcher fetchSiteInfoForSite:self.site]
    .then(^(id result){
        @strongify(self);
        self.siteInfo = result;
        [self.delegate controller:self didSetItems:self.items];
    })
    .catch(^(NSError* error){
    });
}

@end
