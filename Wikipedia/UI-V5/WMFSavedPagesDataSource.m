
#import "WMFSavedPagesDataSource.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKArticle.h"
#import "MediaWikiKit.h"
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSString+Extras.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource ()

@end

@implementation WMFSavedPagesDataSource

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages {
    self = [super initWithTarget:savedPages keyPath:WMF_SAFE_KEYPATH(savedPages, entries)];
    if (self) {
        self.savedPageList = savedPages;

        self.cellClass = [WMFArticlePreviewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticlePreviewCell* cell,
                                    MWKSavedPageEntry* entry,
                                    UICollectionView* collectionView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKArticle* article = [self articleForIndexPath:indexPath];
            cell.title           = article.title;
            cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
            cell.image           = [article bestThumbnailImage];
            [cell setSummary:[article summary]];
            [cell setSavedPageList:self.savedPageList];
        };
    }
    return self;
}

- (void)setCollectionView:(UICollectionView* __nullable)collectionView {
    [super setCollectionView:collectionView];
    [self.collectionView registerNib:[WMFArticlePreviewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

- (NSArray*)articles {
    return [[self.savedPageList entries] bk_map:^id (id obj) {
        return [self articleForEntry:obj];
    }];
}

- (MWKArticle*)articleForEntry:(MWKSavedPageEntry*)entry {
    return [[self dataStore] articleWithTitle:entry.title];
}

- (MWKDataStore*)dataStore {
    return self.savedPageList.dataStore;
}

- (nullable NSString*)displayTitle {
    return [MWLocalizedString(@"saved-pages-title", nil) capitalizedString];
}

- (NSUInteger)articleCount {
    return [[self savedPageList] countOfEntries];
}

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return [self articleForEntry:savedEntry];
}

- (NSIndexPath*)indexPathForArticle:(MWKArticle*)article {
    NSUInteger index = [self.articles indexOfObject:article];
    if (index == NSNotFound) {
        return nil;
    }

    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    if (savedEntry) {
        [self.savedPageList removeEntryWithListIndex:savedEntry.title];
        [self.savedPageList save];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSaved;
}

@end

NS_ASSUME_NONNULL_END