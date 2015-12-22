
#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "WMFAnalyticsLogging.h"

@class SSSectionedDataSource, SSArrayDataSource;

@protocol WMFHomeSectionControllerDelegate, WMFTitleListDataSource;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFHomeSectionController <WMFAnalyticsLogging>

@property (nonatomic, weak) id<WMFHomeSectionControllerDelegate> delegate;

- (NSString*)sectionIdentifier;

- (UIImage*)headerIcon;

- (NSAttributedString*)headerText;

- (void)registerCellsInTableView:(UITableView*)tableView;

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;

- (NSArray*)items;

@optional

/**
 *  Determine whether or not an item is selectable.
 *
 *  For example, if the item is just a placeholder which shouldn't be selected. Not implementing this method
 *  assumes that all items should always be selectable.
 *
 *  @param index The index of the item the user is attempting to select.
 *
 *  @return Whether or not the item at the given index should be selected.
 */
- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index;

- (UIImage*)headerButtonIcon;

- (void)performHeaderButtonAction;

/**
 *  Specify the text for an optional footer which allows the user to see a list of more content.
 *
 *  No footer will be displayed if this isn't implemented.
 *
 *  @return The "More" footer text that prompts a user to get more items from a section.
 */
- (NSString*)footerText;

/**
 *  The discovery method associated with where this section's data originated from.
 *
 *  Defaults to @c MWKHistoryDiscoveryMethodSearch if not implemented.
 *
 *  @return A discovery method.
 */
- (MWKHistoryDiscoveryMethod)discoveryMethod;

@end

/**
 *  Protocol for sections which display articles in some form (e.g. nearby or related articles).
 */
@protocol WMFArticleHomeSectionController <WMFHomeSectionController>

/**
 *  Provide the article title to be pushed in response to an item being tapped.
 *
 *  @param index The index of the cell which was tapped.
 *
 *  @return The title of the item at @c index.
 */
- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index;

@optional

/**
 *  @return A data source which will provide a larger list of items from this section.
 */
- (SSArrayDataSource<WMFTitleListDataSource>*)extendedListDataSource;

@end

/**
 *  Protocol for sections which display something other than articles.
 */
@protocol WMFGenericHomeSectionController <WMFHomeSectionController>

/**
 *  Return a view controller to be presented modally when an item is tapped.
 *
 *  The caller will present the view controller returned by this method modally.
 *
 *  @param index The index of the cell that was tapped.
 *
 *  @return A view controller which displays more details of the content at @c index.
 */
- (UIViewController*)homeDetailViewControllerForItemAtIndex:(NSUInteger)index;

@end

typedef void (^ WMFHomeSectionCellEnumerator)(id cell, NSIndexPath* indexPath);

@protocol WMFHomeSectionControllerDelegate <NSObject>

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items;

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items;

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes;

- (void)controller:(id<WMFHomeSectionController>)controller didFailToUpdateWithError:(NSError*)error;

@end

NS_ASSUME_NONNULL_END