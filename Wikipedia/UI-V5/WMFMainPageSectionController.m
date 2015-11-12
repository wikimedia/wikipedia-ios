
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"

#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

#import "WMFMainPageCell.h"
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFMainPageSectionIdentifier = @"WMFMainPageSectionIdentifier";

@interface WMFMainPageSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) MWKSiteInfoFetcher* siteInfoFetcher;
@property (nonatomic, strong) WMFEnglishFeaturedTitleFetcher* featuredTitlePreviewFetcher;
@property (nonatomic, strong, nullable) AnyPromise* dataPromise;

@property (nonatomic, strong, readonly) MWKSiteInfo* siteInfo;
@property (nonatomic, strong, readonly) MWKSearchResult* featuredArticlePreview;
@property (nonatomic, strong) id data;

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

- (WMFEnglishFeaturedTitleFetcher*)featuredTitlePreviewFetcher {
    if (_featuredTitlePreviewFetcher == nil) {
        _featuredTitlePreviewFetcher = [[WMFEnglishFeaturedTitleFetcher alloc] init];
    }
    return _featuredTitlePreviewFetcher;
}

+ (NSDateFormatter*)dateFormatter {
    NSParameterAssert([NSThread isMainThread]);
    static NSDateFormatter* dateFormatter;
    if (dateFormatter == nil) {
        dateFormatter           = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return dateFormatter;
}

- (MWKSiteInfo*)siteInfo {
    return [self.data isKindOfClass:[MWKSiteInfo class]] ? self.data : nil;
}

- (MWKSearchResult*)featuredArticlePreview {
    return [self.data isKindOfClass:[MWKSearchResult class]] ? self.data : nil;
}

#pragma mark - HomeSectionController

- (id)sectionIdentifier {
    return WMFMainPageSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (NSAttributedString*)headerText {
    NSString* featuredDate = [[WMFMainPageSectionController dateFormatter] stringFromDate:[NSDate date]];
    return [[NSAttributedString alloc] initWithString:featuredDate attributes:nil];
}

- (NSArray*)items {
    id data = self.featuredArticlePreview ? : self.siteInfo;
    if (data) {
        return @[data];
    } else {
        return @[];
    }
}

- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    if (self.featuredArticlePreview) {
        return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:self.featuredArticlePreview.displayTitle fragment:nil];
    } else if (self.siteInfo) {
        return self.siteInfo.mainPageTitle;
    } else {
        return nil;
    }
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFMainPageCell wmf_classNib]
     forCellWithReuseIdentifier:[WMFMainPageCell identifier]];
    [collectionView registerNib:[WMFArticlePreviewCell wmf_classNib]
     forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    if (self.siteInfo) {
        return [WMFMainPageCell cellForCollectionView:collectionView indexPath:indexPath];
    } else if (self.featuredArticlePreview) {
        return [WMFArticlePreviewCell cellForCollectionView:collectionView indexPath:indexPath];
    }
    DDLogWarn(@"Unexpected dequeue cell call.");
    return nil;
}

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFMainPageCell class]]) {
        WMFMainPageCell* mainPageCell = (WMFMainPageCell*)cell;
        mainPageCell.mainPageTitle.text = self.siteInfo.mainPageTitleText;
    } else if ([cell isKindOfClass:[WMFArticlePreviewCell class]]) {
        WMFArticlePreviewCell* previewCell = (WMFArticlePreviewCell*)cell;
        previewCell.title           = [self titleForItemAtIndex:indexPath.row];
        previewCell.descriptionText = self.featuredArticlePreview.wikidataDescription;
        previewCell.imageURL        = self.featuredArticlePreview.thumbnailURL;
        [previewCell setSummary:self.featuredArticlePreview.extract];
        [previewCell setSavedPageList:self.savedPageList];
    }
}

#pragma mark - Fetching

- (void)fetchData {
    if (self.dataPromise) {
        DDLogInfo(@"Fetch is already pending, skipping redundant call.");
        return;
    }

    @weakify(self);
    self.dataPromise = [self fetchDataForSite].then(^(id data) {
        @strongify(self);
        self.dataPromise = nil;
        self.data = data;
        [self.delegate controller:self didSetItems:self.items];
    })
                       .catch(^(NSError* error){
        @strongify(self);
        self.dataPromise = nil;
        [self.delegate controller:self didFailToUpdateWithError:error];
    });
}

/**
 *  Fetch the data for the current site.
 *
 *  If site is en.wikipedia.org, fetch a preview of today's featured article. Otherwise, get Main Page title from
 *  site info.
 *
 *  @return A promise which resolves to the data (either @c MWKSiteInfo or @c MWKSearchResult).
 */
- (AnyPromise*)fetchDataForSite {
    if ([self.site.language isEqualToString:@"en"] || [self.site.language isEqualToString:@"en-US"]) {
        return [self.featuredTitlePreviewFetcher fetchFeaturedArticlePreviewForDate:[NSDate date]];
    } else {
        return [self.siteInfoFetcher fetchSiteInfoForSite:self.site];
    }
}

@end

NS_ASSUME_NONNULL_END
