

#import "WMFRelatedSectionController.h"

#import "WMFRelatedSearchFetcher.h"

#import "MWKTitle.h"
#import "WMFRelatedSearchResults.h"
#import "MWKLocationSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"

static NSString* const WMFNearbySectionIdentifierPrefix = @"WMFRelatedSectionIdentifier";

static NSUInteger const WMFRelatedSectionMaxResults = 3;

@interface WMFRelatedSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) WMFRelatedSearchFetcher* relatedSearchFetcher;

@property (nonatomic, strong, readwrite) WMFRelatedSearchResults* relatedResults;

@end

@implementation WMFRelatedSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithArticleTitle:(MWKTitle*)title relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher {
    NSParameterAssert(title);
    NSParameterAssert(relatedSearchFetcher);

    self = [super init];
    if (self) {
        relatedSearchFetcher.maximumNumberOfResults = WMFRelatedSectionMaxResults;
        self.relatedSearchFetcher                   = relatedSearchFetcher;

        self.title = title;
    }
    [self fetchNearbyArticlesWithTitle:self.title];
    return self;
}

- (id)sectionIdentifier {
    return [WMFNearbySectionIdentifierPrefix stringByAppendingString:self.title.text];
}

- (NSAttributedString*)headerText {
    NSMutableAttributedString* link = [[NSMutableAttributedString alloc] initWithString:self.title.text];
    [link addAttribute:NSLinkAttributeName value:self.title.desktopURL range:NSMakeRange(0, link.length)];
    [link insertAttributedString:[[NSAttributedString alloc] initWithString:@"Because you read " attributes:nil] atIndex:0];
    return link;
}

- (NSString*)footerText {
    return @"More like this";
}

- (NSArray*)items {
    return self.relatedResults.results;
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    MWKSearchResult* result = self.items[index];
    MWKSite* site           = self.relatedResults.title.site;
    MWKTitle* title         = [site titleWithString:result.displayTitle];
    return title;
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFArticlePreviewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFArticlePreviewCell cellForCollectionView:collectionView indexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object inCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewCell class]]) {
        WMFArticlePreviewCell* previewCell = (id)cell;
        MWKLocationSearchResult* result    = object;
        previewCell.titleText             = result.displayTitle;
        previewCell.descriptionText       = result.wikidataDescription;
        previewCell.imageURL              = result.thumbnailURL;
        previewCell.summaryAttributedText = nil;
        previewCell.title                 = [self titleForItemAtIndex:indexPath.row];
    }
}

#pragma mark - Section Updates

- (void)updateSectionWithResults:(WMFRelatedSearchResults*)results {
    [self.delegate controller:self didSetItems:results.results];
}

- (void)updateSectionWithSearchError:(NSError*)error {
}

#pragma mark - Fetch

- (void)fetchNearbyArticlesWithTitle:(MWKTitle*)title {
    if (self.relatedSearchFetcher.isFetching) {
        return;
    }

    @weakify(self);
    [self.relatedSearchFetcher fetchArticlesRelatedToTitle:title]
    .then(^(WMFRelatedSearchResults* results){
        @strongify(self);
        self.relatedResults = results;
        [self updateSectionWithResults:results];
    })
    .catch(^(NSError* error){
        @strongify(self);
        [self updateSectionWithSearchError:error];
    });
}

@end
