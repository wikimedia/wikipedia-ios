
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"

#import "MWKSite.h"
#import "MWKSiteInfo.h"

#import "WMFMainPageCell.h"
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

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFMainPageCell wmf_classNib] forCellWithReuseIdentifier:[WMFMainPageCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFMainPageCell cellForCollectionView:collectionView indexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFMainPageCell class]]) {
        WMFMainPageCell* mainPageCell = (id)cell;
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
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
    });
}

@end
