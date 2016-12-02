//
//  SSSection.h
//  ExampleSSDataSources
//
//  Created by Jonathan Hersh on 8/29/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * SSSection models a single section in a multi-sectioned table or collection view
 * powered by `SSSectionedDataSource`.
 * It maintains an array of items appearing within its section,
 * plus a header and footer string.
 */

@interface SSSection : NSObject <NSCopying>

/**
 * Create a section with an array of items.
 */
+ (instancetype) sectionWithItems:(NSArray *)items;

/**
 * Create a section with an array of items, plus a header, footer, and identifier.
 */
+ (instancetype) sectionWithItems:(NSArray *)items
                           header:(NSString *)header
                           footer:(NSString *)footer
                       identifier:(id)identifier;

/**
 * Sometimes you just need a section with a given number of cells
 * and all the cell creation and configuration is handled with values stored elsewhere.
 * This method creates a section with the specified number of placeholder objects.
 */
+ (instancetype) sectionWithNumberOfItems:(NSUInteger)numberOfItems;

/**
 *  Create a section with some placeholder items.
 *
 *  @param numberOfItems number of items to use
 *  @param header        nil or section header
 *  @param footer        nil or section footer
 *  @param identifier    nil or section identifier
 *
 *  @return an initialized section with some placeholder items
 */
+ (instancetype) sectionWithNumberOfItems:(NSUInteger)numberOfItems
                                   header:(NSString *)header
                                   footer:(NSString *)footer
                               identifier:(id)identifier;

/**
 * Return the number of items in this section.
 */
- (NSUInteger) numberOfItems;

/**
 * Return the item at a particular index.
 */
- (id) itemAtIndex:(NSUInteger)index;

/**
 *  Section items. You probably shouldn't mutate this directly;
 *  instead see SSSectionedDataSource's
 *     insertItem:atIndexPath:
 *     insertItems:atIndexes:inSection:
 */
@property (nonatomic, strong, readonly) NSMutableArray *items;

/**
 * It can be helpful to assign an identifier to each section
 * particularly when constructing tables that have dynamic numbers and types of sections.
 * This identifier is used in the `SSSectionedDataSource` helper method
 * indexOfSectionWithIdentifier:.
 */
@property (nonatomic, strong) id sectionIdentifier;

/**
 * Simple strings to use for headers and footers.
 * Alternatively, you can use an `SSBaseHeaderFooterView`.
 * See the headerClass and footerClass properties.
 */
@property (nonatomic, copy) NSString *header;

/**
 *  Optional string for footer text.
 */
@property (nonatomic, copy) NSString *footer;

/**
 * Optional custom classes to use for header views.
 * Defaults to SSBaseHeaderFooterView.
 */
@property (nonatomic, weak) Class headerClass;

/**
 *  Optional custom class for footer views.
 *  Defaults to SSBaseHeaderFooterView.
 */
@property (nonatomic, weak) Class footerClass;

/**
 * Optional header and footer height.
 * Given that `tableView:heightForHeaderInSection:` and friends are part of
 * UITableViewDelegate, NOT UITableViewDataSource, 
 * SSDataSources does not provide an implementation. These properties
 * are merely helpers so that you can write simpler delegate code similar to this:
 *
   - (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
        return [mySectionedDataSource heightForHeaderInSection:section];
   }
 *
 */
@property (nonatomic, assign) CGFloat headerHeight;

/**
 *  Helper storage for section footer height.
 */
@property (nonatomic, assign) CGFloat footerHeight;

/**
 *  YES if this section is currently expanded, NO if collapsed. Specific to SSExpandingDataSource.
 *  See setSection:expanded: and
 *  setSectionAtIndex:expanded: in SSExpandingDataSource.
 */
@property (nonatomic, assign, readonly, getter=isExpanded) BOOL expanded;

@end
