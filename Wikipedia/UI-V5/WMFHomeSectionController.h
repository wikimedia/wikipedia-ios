
#import <Foundation/Foundation.h>

@class SSSectionedDataSource, SSArrayDataSource, MWKSavedPageList;

@protocol WMFHomeSectionControllerDelegate, WMFArticleListDataSource;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFHomeSectionController <NSObject>

@property (nonatomic, weak) id<WMFHomeSectionControllerDelegate> delegate;

- (NSString*)sectionIdentifier;

- (NSAttributedString*)headerText;

- (NSString*)footerText;

- (void)registerCellsInCollectionView:(UICollectionView*)collectionView;

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath;

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object inCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath;

- (NSArray*)items;

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index;

/**
 *  @return A data source which will provide a larger list of items from this section.
 */
- (SSArrayDataSource<WMFArticleListDataSource>*)extendedListDataSource;

@optional

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index;

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList;

/**
 *  The discovery method associated with where this section's data originated from.
 *
 *  Defaults to @c MWKHistoryDiscoveryMethodSearch if not implemented.
 *
 *  @return A discovery method.
 */
- (MWKHistoryDiscoveryMethod)discoveryMethod;

@end

typedef void (^ WMFHomeSectionCellEnumerator)(id cell, NSIndexPath* indexPath);

@protocol WMFHomeSectionControllerDelegate <NSObject>

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items;

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items;

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes;

- (void)controller:(id<WMFHomeSectionController>)controller enumerateVisibleCells:(WMFHomeSectionCellEnumerator)enumerator;

- (CGFloat)maxItemWidth;

@end

NS_ASSUME_NONNULL_END