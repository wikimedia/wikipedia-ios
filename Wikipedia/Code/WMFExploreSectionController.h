
#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WMFExploreSectionController <WMFAnalyticsLogging>

/**
 *  The items of the section. Must be KVO-able
 */
@property (nonatomic, strong, readonly) NSArray* items;

/**
 *  Called to update data if no items or errors
 */
- (AnyPromise*)fetchDataIfNeeded;


/**
 *  Called to update data no matter what state
 */
- (AnyPromise*)fetchDataUserInitiated;

/**
 *  Clear items and errors
 */
- (void)resetData;

/**
 *  Called when a section is about to be displayed
 */
- (void)willDisplaySection;

/**
 *  Called when finished displaying a section
 */
- (void)didEndDisplayingSection;

/**
 *  Used to uniquely identify a section
 *
 *  @return The identifier
 */
- (NSString*)sectionIdentifier;

/**
 *  An icon to be displayed in the section's header
 *
 *  @return An image
 */
- (UIImage*)headerIcon;

/**
 *  The text to be displayed in the header.
 *  Note this is an attributed stirng to allow links to be embeded
 *  Additional styling will be added bfore display time.
 *
 *  @return The header string
 */
- (NSAttributedString*)headerText;

/**
 *  Called to allow the controller to register cells in the table view
 *
 *  @param tableView The tableView
 */
- (void)registerCellsInTableView:(UITableView*)tableView;

/**
 *  Return the identifier for the cell at the specified index.
 *  Used to dequeue a cell
 *
 *  @param index The index of the object
 *
 *  @return The identifer for the cell to be dequeued
 */
- (NSString*)cellIdentifierForItemIndexPath:(NSIndexPath*)indexPath;

//- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;

/**
 *  Description
 *
 *  @param cell      The cell to configure
 *  @param indexPath The indexPath of the cell
 */
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

/**
 *  Estimated height of the cells in the section
 *
 *  @return The height
 */
- (CGFloat)estimatedRowHeight;

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
- (BOOL)shouldSelectItemAtIndexPath:(NSIndexPath*)indexPath;

/**
 *  The discovery method associated with where this section's data originated from.
 *
 *  @return A discovery method.
 */
- (MWKHistoryDiscoveryMethod)discoveryMethod;

@end

/**
 *  Protocol for sections with an overflow button on the right side of the header
 */
@protocol WMFHeaderMenuProviding <NSObject>


/**
 * Provide an action sheet with menu options
 * NOTE: you cannot currently implement both WMFHeaderMenuProviding and WMFHeaderActionProviding - they are implemented using the same button
 */
- (UIActionSheet*)menuActionSheet;

@end
/**
 *  Protocol for sections with an custom action button on the right side of the header.
 * NOTE: you cannot currently implement both WMFHeaderMenuProviding and WMFHeaderActionProviding - they are implemented using the same button
 */
@protocol WMFHeaderActionProviding <NSObject>

/**
 *  Specify the image for the button
 *
 *  @return The image
 */
- (UIImage*)headerButtonIcon;

/**
 *  Perform the action associated with the button
 */
- (void)performHeaderButtonAction;

@end

/**
 *  Protocol for controllers displaying a footer
 */
@protocol WMFMoreFooterProviding <NSObject>

/**
 *  Specify the text for an optional footer which allows the user to see a list of more content.
 *
 *  No footer will be displayed if this isn't implemented.
 *
 *  @return The "More" footer text that prompts a user to get more items from a section.
 */
- (NSString*)footerText;

/**
 *  @return A view controller with will provide a more data for this section.
 */
- (UIViewController*)moreViewController;

@end

/**
 *  Protocol for sections which display articles in some form (e.g. nearby or related articles).
 */
@protocol WMFTitleProviding <NSObject>

/**
 *  Provide the article title to be pushed in response to an item being tapped.
 *
 *  @param index The index of the cell which was tapped.
 *
 *  @return The title of the item at @c index.
 */
- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath;

@end

/**
 *  Protocol for sections which display something other than articles.
 */
@protocol WMFDetailPresenting <NSObject>

/**
 *  Return a view controller to be presented modally when an item is tapped.
 *
 *  The caller will present the view controller returned by this method modally.
 *
 *  @param indexPath The indexPath of the cell that was tapped.
 *
 *  @return A view controller which displays more details of the content at @c index.
 */
- (UIViewController*)exploreDetailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath;

@end



NS_ASSUME_NONNULL_END