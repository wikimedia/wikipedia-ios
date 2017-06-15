#import <WMF/MWKList.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Block passed to lists when an entry is being updated.
 *
 *  @param entry The entry to update.
 *
 *  @return Whether or not the list should be considered dirty after the update.
 */
typedef BOOL (^MWKListUpdateBlock)(MWKListEntry entry);

@interface MWKList (Subclasses)

/**
 *  Invoked during @c initWithEntries: to set the receiver's internal @c entries to the given objects.
 *
 *  Override this method to perform any preprocessing on the entries before they're set.  Your implementation should
 *  call @c super at the end.
 *
 *  @param entries The entries to be set in the receiver.
 */
- (void)importEntries:(nullable NSArray *)entries;

/**
 *  Update the entry associated with @c listIndex, updating the internal @c dirty flag if necessary.
 *
 *  @param listIndex The index of the entry to update.
 *  @param update    A block which is given the entry to modify.
 *
 *  @see MWKListUpdateBlock
 */
- (void)updateEntryWithListIndex:(MWKListIndex)listIndex update:(MWKListUpdateBlock)update;

/**
 *  Insert @c entry at the given index.
 *
 *  @param entry The entry to insert.
 *  @param index The index in the list to insert it, will raise an exception if out of bounds.
 */
- (void)insertEntry:(MWKListEntry)entry atIndex:(NSUInteger)index;

/**
 *  Return sort descriptors used for sorting the list.
 *  Sorting will occur whenever the list is updated.
 *  The defualt implementation will return nil which results in no sorting
 *
 *  @return The sort descriptors to use for sorting the entries
 */
- (nullable NSArray<NSSortDescriptor *> *)sortDescriptors;

/*
 * Indicates if the list has been mutated since the last save.
 */
@property (nonatomic, assign, readonly) BOOL dirty;

/**
 *  Subclasses must implement to support saving
 */
- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler;

@end

NS_ASSUME_NONNULL_END
