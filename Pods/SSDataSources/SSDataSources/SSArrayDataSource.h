//
//  SSArrayDataSource.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 6/7/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSBaseDataSource.h"
#import <CoreData/CoreData.h>

/**
 * Data source for single-sectioned table and collection views.
 */

@interface SSArrayDataSource : SSBaseDataSource

/**
 * Create a new array data source by specifying an array of items.
 */
- (instancetype) initWithItems:(NSArray *)items;

/**
 * Create a new array data source by specifying a target and key path to observe
 * for array content.
 *
 * @param target - the object that the given key path is relative to
 * @param keyPath - a key path for that identifiers an NSArray of data for the receiver
 *
 * @warning The `target` parameter is strongly referenced by the receiver. Make
 *          sure you don't create a retain cycle by having `target` also hold a
 *          strong reference to the receiver.
 */
- (instancetype) initWithTarget:(id)target keyPath:(NSString *)keyPath;

#pragma mark - Item access

/**
 * Helper for managed objects. As with `indexPathForItem`, but for managed object IDs.
 */
- (NSIndexPath *) indexPathForItemWithId:(NSManagedObjectID *)itemId;

#pragma mark - All or None Operations

/**
 * Returns all items in the data source.
 */
- (NSArray *) allItems;

/**
 * Remove all objects in the data source.
 */
- (void) clearItems;

/**
 * Remove all objects in the data source.
 * Alias for clearItems.
 */
- (void) removeAllItems;

/**
 * Replace all items in the data source.
 * This will reload the table or collection view.
 */
- (void) updateItems:(NSArray *)newItems;

#pragma mark - Adding Items

/**
 * Append a single item to the end of the items array.
 */
- (void) appendItem:(id)item;

/**
 * Add some more items to the end of the items array.
 */
- (void) appendItems:(NSArray *)newItems;

/**
 * Insert an item at the specified index.
 */
- (void) insertItem:(id)item atIndex:(NSUInteger)index;

/**
 * Insert some items at the specified indexes.
 * The count of `items` should be equal to the number of `indexes`.
 */
- (void) insertItems:(NSArray *)items atIndexes:(NSIndexSet *)indexes;

#pragma mark - Replacing items

/**
 * Replace an item.
 */
- (void) replaceItemAtIndex:(NSUInteger)index withItem:(id)item;

/**
 *  Replace items at the specified indexes with items from the provided array.
 */
- (void) replaceItemsAtIndexes:(NSIndexSet *)indexes withItemsFromArray:(NSArray *)array;

/**
 * Replace items in the specified range with items from the provided array.
 */
- (void) replaceItemsInRange:(NSRange)range withItemsFromArray:(NSArray *)otherArray;
 
#pragma mark - Removing items

/**
 * Remove the item at the specified index.
 */
- (void) removeItemAtIndex:(NSUInteger)index;

/**
 * Remove items in the specified range.
 */
- (void) removeItemsInRange:(NSRange)range;

/**
 * Remove items at the specified indexes.
 */
- (void) removeItemsAtIndexes:(NSIndexSet *)indexes;

/**
 * Remove items found in the provided array.
 * Items in the provided array should respond to hash and isEqual:.
 */
- (void) removeItems:(NSArray *)items;

#pragma mark - Moving items

/**
 * Move an item to a new index.
 */
- (void) moveItemAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2;

@end
