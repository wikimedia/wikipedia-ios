
@import UIKit;

@class MWKHistoryEntry;
@class WMFArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFFeedSectionControlling <NSObject>

/**
 *  An icon to be displayed in the section's header
 *
 *  @return An image
 */
- (UIImage *)headerIcon;

/**
 *  Color used for icon tint
 *
 *  @return A color
 */
- (UIColor *)headerIconTintColor;

/**
 *  Background color of section's header icon container view
 *
 *  @return A color
 */
- (UIColor *)headerIconBackgroundColor;

/**
 *  The text to be displayed on the first line of the header.
 *  Note this is an attributed stirng to allow links to be embeded
 *  Additional styling will be added before display time.
 *
 *  @return The header title string
 */
- (NSAttributedString *)headerTitle;

/**
 *  The text to be displayed on the second line of the header.
 *  Note this is an attributed stirng to allow links to be embeded
 *  Additional styling will be added bfore display time.
 *
 *  @return The header sub-title string
 */
- (NSAttributedString *)headerSubTitle;


/**
 *  Return the identifier for the cell at the specified index.
 *  Used to dequeue a cell
 *
 *  @return The identifer for the cell to be dequeued
 */
- (NSString *)cellIdentifier;



- (NSUInteger)maxNumberOfCells;


@optional

/**
 *  Called when a section is about to be displayed.
 *
 *  This can happen when one of a section's cells scrolls on screen, or the entire table view appears and the receiver's section is visible. Note that
 *  cells can also rapidly appear & disappear as the result of table reloads.
 *
 *  @warning
 *  This method must be idempotent, as it will be called multiple times for each cell appearance.
 */
- (void)willDisplaySection;

/**
 *  Called when the receiver's section in the table is no longer visible.
 *
 *  This can happen when either the cells are scolled offscreen (invoked after last cell scolls away) or when the entire
 *  table view disappears (e.g. switching tabs). Note that cells can also rapidly appear & disappear as the result of table reloads.
 */
- (void)didEndDisplayingSection;

- (BOOL)prefersWiderColumn;

@end

NS_ASSUME_NONNULL_END
