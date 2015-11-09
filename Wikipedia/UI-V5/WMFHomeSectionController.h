
#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"

@class SSSectionedDataSource, SSArrayDataSource;

@protocol WMFHomeSectionControllerDelegate, WMFTitleListDataSource;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFHomeSectionController <NSObject>

@property (nonatomic, weak) id<WMFHomeSectionControllerDelegate> delegate;

- (NSString*)sectionIdentifier;

- (UIImage*)headerIcon;

- (NSAttributedString*)headerText;

- (void)registerCellsInCollectionView:(UICollectionView*)collectionView;

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath;

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object inCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath;

- (NSArray*)items;

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index;

@optional

- (UIImage*)headerButtonIcon;
- (void)    performHeaderButtonAction;

/**
 *  @return Return the "More" footer text that prompts a user to get more items from a section.
 *  Not implementing this method means that no footer will be displayed
 */
- (NSString*)footerText;

/**
 *  @return A data source which will provide a larger list of items from this section.
 */
- (SSArrayDataSource<WMFTitleListDataSource>*)extendedListDataSource;

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index;

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

- (void)controller:(id<WMFHomeSectionController>)controller didFailToUpdateWithError:(NSError*)error;

- (CGFloat)maxItemWidth;

@end

NS_ASSUME_NONNULL_END