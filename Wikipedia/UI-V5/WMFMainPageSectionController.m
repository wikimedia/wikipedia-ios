
#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFENFeaturedTitleFetcher.h"

#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

#import "WMFMainPageCell.h"
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"

static NSString* const WMFMainPageSectionIdentifier = @"WMFMainPageSectionIdentifier";

@interface WMFMainPageSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) MWKSiteInfoFetcher* siteInfoFetcher;
@property (nonatomic, strong) WMFENFeaturedTitleFetcher* featuredTitlePreviewFetcher;
@property (nonatomic, strong) AnyPromise* dataPromise;

@property (nonatomic, strong) MWKSiteInfo* siteInfo;
@property (nonatomic, strong) MWKSearchResult* featuredArticlePreview;

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

- (MWKSiteInfoFetcher*)siteInfoFetcher {
    if (_siteInfoFetcher == nil) {
        _siteInfoFetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _siteInfoFetcher;
}

- (WMFENFeaturedTitleFetcher*)featuredTitlePreviewFetcher {
    if (_featuredArticlePreview == nil) {
        _featuredTitlePreviewFetcher = [[WMFENFeaturedTitleFetcher alloc] init];
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
        return nil;
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
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

- (void)fetchData {
    if (self.dataPromise) {
        return;
    }

    @weakify(self);
    self.dataPromise =
        [self fetchFeaturedTitleIfAvailable]
        .catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError* error) {
        @strongify(self);
        if (!self) {
            [AnyPromise promiseWithValue:[NSError cancelledError]];
        }
        if (!error.cancelled) {
            DDLogWarn(@"Failed to fetch featured title preview, falling back to main page. Error: %@", error);
        }
        self.dataPromise = [self fetchSiteInfo];
        return self.dataPromise;
    })
        .catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError* error){
        @strongify(self);
        self.dataPromise = nil;
        if (!error.cancelled) {
            [self.delegate controller:self didFailToUpdateWithError:error];
        }
    });
}

- (AnyPromise*)fetchSiteInfo {
    @weakify(self);
    return [self.siteInfoFetcher fetchSiteInfoForSite:self.site].then(^(MWKSiteInfo* siteInfo){
        @strongify(self);
        self.dataPromise = nil;

        self.siteInfo = siteInfo;
        [self.delegate controller:self didSetItems:self.items];
    });
}

- (AnyPromise*)fetchFeaturedTitleIfAvailable {
    if (![self.site.language isEqualToString:@"en"] && ![self.site.language isEqualToString:@"en-US"]) {
        return [AnyPromise promiseWithValue:[NSError cancelledError]];
    }
    @weakify(self);
    return [self.featuredTitlePreviewFetcher featuredArticlePreviewForDate:nil].then(^(MWKSearchResult* featuredTitlePreview) {
        @strongify(self);
        self.dataPromise = nil;

        self.featuredArticlePreview = featuredTitlePreview;
        [self.delegate controller:self didSetItems:self.items];
    });
}

@end
