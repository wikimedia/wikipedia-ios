//
//  SSExpandingDataSource.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 11/26/14.
//  Copyright (c) 2014 Splinesoft. All rights reserved.
//

#import "SSSectionedDataSource.h"

/**
 * A data source for multi-sectioned table and collection views that allows for sections
 * to be expanded and collapsed.
 * Each section is modeled using an `SSSection` object.
 * See `SSection` and `SSSectionedDataSource` for more details.
 */

#pragma mark - SSExpandingDataSource

@interface SSExpandingDataSource : SSSectionedDataSource

/**
 *  SSExpandingDataSource has no specific initializers of its own.
 *  Create an instance of SSExpandingDataSource with one of the
 *  SSSectionedDataSource initializers.
 */

typedef NSInteger (^SSCollapsedSectionCountBlock) (SSSection *section,
                                                   NSInteger sectionIndex);

/**
 *  SSExpandingDataSource allows you to specify the maximum number of rows that
 *  should appear in each section when that section is collapsed.
 *  Different sections may display different numbers of rows when collapsed.
 *
 *  A collapsed section will display, at maximum, the number of items you return from this block
 *  for that section.
 *
 *  Inserting more items into a collapsed section will display more rows in the table or collection view
 *  for that section only up to the maximum collapsed item count for that section.
 *
 *  An expanded section does not limit the number of items that it displays.
 *
 *  @param section      the section being expanded or collapsed
 *  @param sectionIndex the index of this section
 *
 *  @return the maximum number of rows to display in this section when collapsed
 */
@property (nonatomic, copy) SSCollapsedSectionCountBlock collapsedSectionCountBlock;

#pragma mark - Section/Index helpers

/**
 *  Ask the data source whether the section at a specified index is expanded.
 *
 *  @param index the index to test
 *
 *  @return whether the section at that index is expanded
 */
- (BOOL) isSectionExpandedAtIndex:(NSInteger)index;

/**
 *  Ask the data source if an item at the specified indexpath is currently visible,
 *  taking into account the expanded/collapsed state of that section,
 *  plus the collapsed row count for that section from your `collapsedSectionCountBlock`.
 *
 *  @param indexPath indexpath to test
 *
 *  @return whether an item at that index path is currently visible
 */
- (BOOL) isItemVisibleAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Returns an NSIndexSet containing the indexes of the currently-expanded sections.
 *
 *  @return an indexset indicating currently-expanded sections
 */
- (NSIndexSet *) expandedSectionIndexes;

/**
 *  Return the maximum number of rows that will be displayed in this section when it is collapsed.
 *
 *  This method calls your `collapsedSectionCountBlock`.
 *  If you do not specify a `collapsedSectionCountBlock`, collapsed sections default to 0 items.
 *
 *  @param section section to test
 *
 *  @return the number of collapsed rows in this section
 */
- (NSUInteger) numberOfCollapsedRowsInSection:(NSInteger)section;

#pragma mark - Expanding Sections

/**
 *  Toggle the expanded/collapsed state of the section at the specified index.
 *
 *  @param index section index to toggle
 */
- (void) toggleSectionAtIndex:(NSInteger)index;

/**
 *  Expand or collapse the section at the specified index.
 *  Inserts or deletes rows as appropriate to bring this section to the number of rows
 *  you specify in `collapsedSectionCountBlock`.
 *
 *  @param index    the index of the section to expand or collapse
 *  @param expanded whether to expand (YES) or collapse (NO) this section
 */
- (void) setSectionAtIndex:(NSInteger)index expanded:(BOOL)expanded;

/**
 *  Expand or collapse a section, as above, if you already have the SSSection object handy.
 *
 *  @param section  the section to expand or collapse
 *  @param expanded whether to expand (YES) or collapse (NO) this section
 */
- (void) setSection:(SSSection *)section expanded:(BOOL)expanded;

@end
