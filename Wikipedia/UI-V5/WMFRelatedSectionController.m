#import "WMFRelatedSectionController.h"

// Networking & Model
#import "WMFRelatedSearchFetcher.h"
#import "MWKTitle.h"
#import "WMFRelatedSearchResults.h"
#import "MWKRelatedSearchResult.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

// View
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"

// Style
#import "UIFont+WMFStyle.h"


static NSString* const WMFRelatedSectionIdentifierPrefix = @"WMFRelatedSectionIdentifier";
static NSUInteger const WMFNumberOfExtractLines          = 4;
static NSUInteger const WMFRelatedSectionMaxResults      = 3;

@interface WMFRelatedSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) WMFRelatedSearchFetcher* relatedSearchFetcher;

@property (nonatomic, strong, readwrite) WMFRelatedSearchResults* relatedResults;

@end

@implementation WMFRelatedSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                relatedSearchFetcher:(WMFRelatedSearchFetcher*)relatedSearchFetcher
                            delegate:(id<WMFHomeSectionControllerDelegate>)delegate {
    NSParameterAssert(title);
    NSParameterAssert(relatedSearchFetcher);
    self = [super init];
    if (self) {
        relatedSearchFetcher.maximumNumberOfResults = WMFRelatedSectionMaxResults;
        self.relatedSearchFetcher                   = relatedSearchFetcher;
        self.title                                  = title;
        self.delegate                               = delegate;
    }
    [self fetchRelatedArticlesWithTitle:self.title];
    return self;
}

- (id)sectionIdentifier {
    return [WMFRelatedSectionIdentifierPrefix stringByAppendingString:self.title.text];
}

- (NSAttributedString*)headerText {
    NSMutableAttributedString* link = [[NSMutableAttributedString alloc] initWithString:self.title.text];
    [link addAttribute:NSLinkAttributeName value:self.title.desktopURL range:NSMakeRange(0, link.length)];
    // TODO: localize
    [link insertAttributedString:[[NSAttributedString alloc] initWithString:@"Because you read " attributes:nil] atIndex:0];
    return link;
}

- (NSString*)footerText {
    // TODO: localize
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

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewCell class]]) {
        WMFArticlePreviewCell* previewCell = (id)cell;
        previewCell.summaryLabel.numberOfLines = WMFNumberOfExtractLines;
        MWKRelatedSearchResult* result = object;
        previewCell.titleText       = result.displayTitle;
        previewCell.descriptionText = result.wikidataDescription;
        previewCell.imageURL        = result.thumbnailURL;
        [previewCell setSummaryHTML:result.extractHTML fromSite:self.relatedResults.title.site];
        NSAssert (^{
            UIFont* actualFont = [previewCell.summaryLabel.attributedText attribute:NSFontAttributeName atIndex:0 effectiveRange:nil] ? : previewCell.summaryLabel.font;
            UIFont* requiredFont = [UIFont wmf_htmlBodyFont];
            return [actualFont.familyName isEqualToString:requiredFont.familyName]
            && (fabs(actualFont.pointSize - requiredFont.pointSize) < 0.01);
        } (), @"Expected previewCell to use standard HTML body font! Needed for numberOfExtactCharactersToFetch.");
    }
}

#pragma mark - Section Updates

- (void)updateSectionWithResults:(WMFRelatedSearchResults*)results {
    [self.delegate controller:self didSetItems:results.results];
}

- (void)updateSectionWithSearchError:(NSError*)error {
}

#pragma mark - Fetch

- (NSUInteger)numberOfExtractCharactersToFetch {
    CGFloat maxLabelWidth = [self.delegate maxItemWidth] - WMFArticlePreviewCellTextPadding * 2;
    NSParameterAssert(maxLabelWidth > 0);
    UIFont* summaryHTMLFont           = [UIFont wmf_htmlBodyFont];
    CGFloat approximateCharacterWidth = summaryHTMLFont.xHeight;
    NSUInteger charsPerLine           = ceilf(maxLabelWidth / approximateCharacterWidth);
    // and an extra half line to force UILabel to truncate the string
    return charsPerLine * (WMFNumberOfExtractLines + 0.5);
}

- (void)fetchRelatedArticlesWithTitle:(MWKTitle*)title {
    if (self.relatedSearchFetcher.isFetching) {
        return;
    }

    @weakify(self);
    [self.relatedSearchFetcher fetchArticlesRelatedToTitle:title
                                  numberOfExtactCharacters:[self numberOfExtractCharactersToFetch]]
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
