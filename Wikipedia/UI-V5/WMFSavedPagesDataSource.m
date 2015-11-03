
#import "WMFSavedPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSString+Extras.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@end

@implementation WMFSavedPagesDataSource

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages {
    NSParameterAssert(savedPages);
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
            MWKArticle* article = [[self dataStore] articleWithTitle:entry.title];
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

- (NSArray*)titles {
    return [[self.savedPageList entries] bk_map:^id (MWKSavedPageEntry* obj) {
        return obj.title;
    }];
}

- (NSUInteger)titleCount {
    return [[self savedPageList] countOfEntries];
}

- (MWKDataStore*)dataStore {
    return self.savedPageList.dataStore;
}

- (nullable NSString*)displayTitle {
    return MWLocalizedString(@"saved-pages-title", nil);
}

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return savedEntry.title;
}

- (NSIndexPath*)indexPathForTitle:(MWKTitle*)title {
    NSUInteger index = [[self.savedPageList entries] indexOfObjectPassingTest:^BOOL (MWKSavedPageEntry* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([obj.title isEqualToTitle:title]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

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