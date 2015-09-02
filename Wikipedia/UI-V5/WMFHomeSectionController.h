
#import <Foundation/Foundation.h>

@class SSSectionedDataSource;

@protocol WMFHomeSectionControllerDelegate;

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

@optional
- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index;

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