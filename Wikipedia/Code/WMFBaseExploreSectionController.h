
#import <Foundation/Foundation.h>
#import "WMFExploreSectionController.h"

@class WMFEmptySectionTableViewCell;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Base implementation of WMFExploreSectionController protocol
 *  See WMFExploreSectionController.h for further documentation
 */
@interface WMFBaseExploreSectionController : NSObject

- (instancetype)initWithItems:(NSArray*)items;

@property (nonatomic, strong, readonly) NSArray* items;

@end

/**
 *  The methods in this category must be implemented by all subclasses
 */
@interface WMFBaseExploreSectionController (WMFBaseExploreSubclassRequiredMethods)

- (NSString*)cellIdentifier;

- (UINib*)cellNib;

- (void)configureCell:(UITableViewCell*)cell withItem:(id)item atIndexPath:(NSIndexPath*)indexPath;

@end

/**
 *  The methods in this category are optional
 */
@interface WMFBaseExploreSectionController (WMFBaseExploreOptionalMethods)

/**
 *  Default returns a successful promise with the current items
 *  Implementations should resolve promises with an NSArray
 */
- (AnyPromise*)fetchData;

@end

/**
 *  Implement the following methods to support placeholders
 */
@interface WMFBaseExploreSectionController (WMFPlaceholderCellSupport)

/**
 *  The number of placeholder cells to display
 *
 *  @return The number of cells. Default is 3
 */
- (NSUInteger)numberOfPlaceholderCells;

- (nullable NSString*)placeholderCellIdentifier;

- (nullable UINib*)placeholderCellNib;

@end

/**
 *  Implement the following methods to support empty cells
 */
@interface WMFBaseExploreSectionController (WMFEmptyCellSupport)

/**
 *  Return Yes to show an empty cell when there are no results
 *
 *  @return Return YES to show empty cells, otherwise NO. Default = NO
 */
- (BOOL)showsEmptyCell;

/**
 *  Configure the empty cell
 *
 *  @param cell The cell to configure
 */
- (void)configureEmptyCell:(WMFEmptySectionTableViewCell*)cell;


@end

/**
 *  The following methods of WMFExploreSectionController are implemented by WMFBaseExploreSectionController.
 */
@interface WMFBaseExploreSectionController (WMFExploreSectionControllerOverrideMethods)

- (void)resetData;

- (BOOL)shouldSelectItemAtIndexPath:(NSIndexPath*)indexPath;

/**
 *  Default is .Unknown
 */
- (MWKHistoryDiscoveryMethod)discoveryMethod;

@end

/**
 *  The following methods of WMFExploreSectionController are implemented by WMFBaseExploreSectionController.
 *  Subclasses do NOT need to implement these except to change behavior.
 */
@interface WMFBaseExploreSectionController (WMFExploreSectionControllerImplementedMethods)

@property (nonatomic, strong, readonly) NSArray* items;

- (AnyPromise*)fetchDataIfNeeded;

- (AnyPromise*)fetchDataUserInitiated;

- (void)registerCellsInTableView:(UITableView*)tableView;

- (NSString*)cellIdentifierForItemIndexPath:(NSIndexPath*)indexPath;

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

@end



NS_ASSUME_NONNULL_END
