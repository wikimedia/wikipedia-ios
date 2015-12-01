
#import "SSSectionedDataSource.h"
#import <SSDataSources/SSDataSources.h>

@interface SSSectionedDataSource (WMFSectionConvenience)

- (NSIndexSet*)indexesOfItemsInSection:(NSInteger)section;

- (NSArray*)indexPathsOfItemsInSection:(NSInteger)section;

- (void)setItems:(NSArray*)items inSection:(NSInteger)section;

- (void)removeAllItemsInSection:(NSInteger)section;

- (void)reloadCellsAtIndexes:(NSIndexSet*)indexes inSection:(NSInteger)section;

- (void)reloadSection:(NSInteger)section;

- (UICollectionViewCell*)cellForItemAtIndex:(NSInteger)index inSection:(NSInteger)section;

@end
