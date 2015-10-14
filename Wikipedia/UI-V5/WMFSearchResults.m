
#import "WMFSearchResults.h"
#import "WMFSearchResultCell.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKHistoryEntry.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                          articles:(nullable NSArray*)articles
                  searchSuggestion:(nullable NSString*)suggestion {
    self = [super initWithItems:articles];
    if (self) {
        self.searchTerm       = searchTerm;
        self.searchSuggestion = suggestion;

        self.cellClass = [WMFSearchResultCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFSearchResultCell* cell,
                                    MWKArticle* article,
                                    UICollectionView* collectionView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            [cell setTitle:article.title highlightingSubstring:self.searchTerm];
            [cell setSearchResultDescription:article.entityDescription];
            cell.image = [article bestThumbnailImage];
            [cell setSavedPageList:self.savedPageList];
        };
    }
    return self;
}

- (void)setCollectionView:(UICollectionView* __nullable)collectionView {
    [super setCollectionView:collectionView];
    [self.collectionView registerNib:[WMFSearchResultCell wmf_classNib] forCellWithReuseIdentifier:[WMFSearchResultCell identifier]];
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

- (CGFloat)estimatedItemHeight {
    return 60.f;
}

@end

NS_ASSUME_NONNULL_END
