//
//  SSSectionedDataSource.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 8/26/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSBaseDataSource.h"

@class SSBaseHeaderFooterView, SSSection;

/**
 * A data source for multi-sectioned table and collection views.
 * Each section is modeled using an `SSSection` object.
 */

#pragma mark - SSSectionedDataSource

@interface SSSectionedDataSource : SSBaseDataSource

/**
 * Create a sectioned data source with a single section.
 * Creates the `SSSection` object for you.
 */
- (instancetype) initWithItems:(NSArray *)items;

/**
 * Create a sectioned data source with a single SSSection object.
 */
- (instancetype) initWithSection:(SSSection *)section;

/**
 * Create a sectioned data source with multiple sections.
 * Each item in the sections array should be a `SSSection` object.
 */
- (instancetype) initWithSections:(NSArray *)sections;

/**
 * Sections that have 0 items will still display a header and footer
 * in their table or collection view. By default, SSSectionedDataSource
 * will remove these empty sections for you.
 *
 * If YES, automatically removes any section that becomes empty
 * -- that is, the `SSSection` object contains 0 items --
 * after a call to one of the following:
 * 
 * removeItemAtIndexPath:
 * removeItemsAtIndexes:inSection:
 * removeItemsInRange:inSection:
 * adjustSectionAtIndex:toNumberOfItems:
 *
 * Defaults to YES.
 */
@property (nonatomic, assign) BOOL shouldRemoveEmptySections;

/**
 * Sections appearing in the datasource.
 * You should not mutate this directly - rather, use the insert/move/remove accessors below.
 */
@property (nonatomic, strong, readonly) NSMutableArray *sections;

#pragma mark - Section access

/**
 * Return the section object at a particular index.
 * Use `itemAtIndexPath:` for items.
 */
- (SSSection *) sectionAtIndex:(NSInteger)index;

/**
 * Return the first section with a given identifier, or nil if not found.
 */
- (SSSection *) sectionWithIdentifier:(id)identifier;

/**
 * Return the index of the first section with a given identifier, or NSNotFound.
 * See `sectionIdentifier` in SSSection.
 */
- (NSUInteger) indexOfSectionWithIdentifier:(id)identifier;

#pragma mark - Moving sections

/**
 *  Move an entire section to another index.
 *
 *  @param fromIndex index of the section to move
 *  @param toIndex   destination index
 */
- (void) moveSectionAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

#pragma mark - Inserting sections

/**
 * Add a new section to the end of the table or collectionview.
 */
- (void) appendSection:(SSSection *)newSection;

/**
 * Insert a section at a particular index.
 */
- (void) insertSection:(SSSection *)newSection atIndex:(NSInteger)index;

/**
 * Insert some new sections at the specified indexes.
 * Each item in the `sections` array should itself be an SSSection object
 * or an array, in which case an SSSection object will be created for it.
 * The number of `sections` should equal the number of `indexes`.
 */
- (void) insertSections:(NSArray *)sections atIndexes:(NSIndexSet *)indexes;

#pragma mark - Inserting items

/**
 * Insert an item at a particular section (indexPath.section) and row (indexPath.row).
 */
- (void) insertItem:(id)item atIndexPath:(NSIndexPath *)indexPath;

/**
 * Replace an item at a particular section (indexPath.section) and row (indexPath.row).
 * Reloads the cell.
 */
- (void) replaceItemAtIndexPath:(NSIndexPath *)indexPath withItem:(id)item;

/**
 * Insert multiple items within a single section.
 * The number of `items` should be equal to the number of `indexes`.
 */
- (void) insertItems:(NSArray *)items
           atIndexes:(NSIndexSet *)indexes
           inSection:(NSInteger)section;

/**
 * Append multiple items to the end of a single section.
 */
- (void) appendItems:(NSArray *)items toSection:(NSInteger)section;

#pragma mark - Adjusting sections

/**
 *  Adjust the number of items in this section to the desired number of items, then
 *  reload the section. This is particularly useful with sections that contain placeholder
 *  objects; see +[SSSection sectionWithNumberOfItems:]
 *
 *  @param index         the index of the section to adjust
 *  @param numberOfItems the desired number of items for this section. If this is greater
 *  than the number of items currently in this section, then one or more placeholder
 *  objects will be inserted to bring this section up to the desired amount.
 *  If this is less than the number of items currently in this section, then one or more
 *  items will be deleted, starting with the last item in the section and working backwards.
 *
 *  @note if numberOfItems is 0 and shouldRemoveEmptySection is YES, the section will be
 *  removed.
 *
 *  @return YES if one or more items were inserted or removed. NO if there was no action
 *  taken due to numberOfItems being equal to the current number of items in the section.
 */
- (BOOL)adjustSectionAtIndex:(NSUInteger)index
             toNumberOfItems:(NSUInteger)numberOfItems;

#pragma mark - Removing sections

/**
 * Destroy all sections.
 */
- (void) clearSections;

/**
 *  Destroy all sections.
 */
- (void) removeAllSections;

/**
 * Remove the section at a given index.
 */
- (void) removeSectionAtIndex:(NSInteger)index;

/**
 * Remove the sections in a given range.
 */
- (void) removeSectionsInRange:(NSRange)range;

/**
 * Remove the sections at specified indexes.
 */
- (void) removeSectionsAtIndexes:(NSIndexSet *)indexes;

/**
 *  Remove the first section with the specified identifier, 
 *  if such a section is currently in the data source.
 */
- (void) removeSectionWithIdentifier:(id)identifier;

#pragma mark - Removing items

/**
 * Remove the item at a given indexpath.
 */
- (void) removeItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Remove multiple items within a single section.
 */
- (void) removeItemsAtIndexes:(NSIndexSet *)indexes inSection:(NSInteger)section;

/**
 * Remove multiple items in a range within a single section.
 */
- (void) removeItemsInRange:(NSRange)range inSection:(NSInteger)section;

#pragma mark - UITableViewDelegate helpers

/**
 * It is UITableViewDelegate, not UITableViewDataSource,
 * that provides header and footer views.
 * SSDataSources provides these helpers for constructing table header and footer views.
 * Assumes your header/footer view is a subclass of SSBaseHeaderFooterView.
 * See the Example project for sample usage.
 */
- (SSBaseHeaderFooterView *) viewForHeaderInSection:(NSInteger)section;

/**
 *  Construct a footer view for the specified section.
 *
 *  @param section section to use
 *
 *  @return a footer view
 */
- (SSBaseHeaderFooterView *) viewForFooterInSection:(NSInteger)section;

/**
 * As above, but for section header heights.
 * This is simply a shortcut for
 * [myDataSource sectionAtIndex:section].headerHeight;
 */
- (CGFloat) heightForHeaderInSection:(NSInteger)section;

/**
 * As above, but for section footer heights.
 * This is simply a shortcut for
 * [myDataSource sectionAtIndex:section].footerHeight;
 */
- (CGFloat) heightForFooterInSection:(NSInteger)section;

/**
 * As above, for section header titles.
 * This is simply a shortcut for
 * [myDataSource sectionAtIndex:section].header
 */
- (NSString *) titleForHeaderInSection:(NSInteger)section;

/**
 * As above, for section footer titles.
 * This is simply a shortcut for
 * [myDataSource sectionAtIndex:section].footer
 */
- (NSString *) titleForFooterInSection:(NSInteger)section;

@end
