
#import "WMFSearchResults.h"
#import "WMFArticlePreviewCell.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm articles:(nullable NSArray*)articles searchSuggestion:(nullable NSString*)suggestion {
    self = [super initWithItems:articles];
    if (self) {
        self.searchTerm       = searchTerm;
        self.searchSuggestion = suggestion;

        self.cellClass = [WMFArticlePreviewCell class];

        self.cellConfigureBlock = ^(WMFArticlePreviewCell* cell,
                                    MWKArticle* article,
                                    UICollectionView* collectionView,
                                    NSIndexPath* indexPath) {
            cell.titleText             = article.title.text;
            cell.descriptionText       = article.entityDescription;
            cell.image                 = [article bestThumbnailImage];
            cell.summaryAttributedText = nil;
            cell.title                 = article.title;
        };
    }
    return self;
}

- (void)setCollectionView:(UICollectionView*)collectionView {
    [super setCollectionView:collectionView];
    [self.collectionView registerNib:[WMFArticlePreviewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

- (nullable NSString*)displayTitle {
    return self.searchTerm;
}

- (NSArray*)articles {
    return [self allItems];
}

- (NSUInteger)articleCount {
    return [self.articles count];
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    return self.articles[indexPath.row];
}

- (NSIndexPath*)indexPathForArticle:(MWKArticle*)article {
    NSUInteger index = [self.articles indexOfObject:article];
    if (index == NSNotFound) {
        return nil;
    }

    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)noResults {
    return (self.searchTerm && [self.articles count] == 0);
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

@end

NS_ASSUME_NONNULL_END
