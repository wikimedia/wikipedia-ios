
#import "MWKDataObject.h"
#import "WMFBlockDefinitions.h"

@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@protocol MWKListObject <NSObject>

- (id <NSCopying, NSObject>)listIndex;

@end

typedef id<MWKListObject> MWKListEntry;
typedef id<NSCopying, NSObject> MWKListIndex;

/**
 * Abstract base class for homogeneous lists of model objects.
 *
 * Can be specialized to contain instances of @c EntryType, which are queryable by index or an associated key of type
 * @c IndexType.
 */
@interface MWKList
<EntryType : MWKListEntry, IndexType :  MWKListIndex> : MWKDataObject<NSFastEnumeration>
// Note: ObjC generics give uncrustify a headache: https://github.com/bengardner/uncrustify/issues/404

 - (instancetype)initWithEntries:(NSArray<EntryType>* __nullable)entries;

/**
 *  Observable - observe to get KVO notifications
 */
 @property (nonatomic, strong, readonly) NSArray<EntryType>* entries;

 #pragma mark - Querying the List

- (NSUInteger)countOfEntries;

- (NSUInteger)indexForEntry:(EntryType)entry;

- (EntryType)entryAtIndex:(NSUInteger)index;

- (EntryType __nullable)entryForListIndex:(IndexType)listIndex;

- (BOOL)containsEntryForListIndex:(IndexType)listIndex;

#pragma mark - Mutating the List

- (void)addEntry:(EntryType)entry;

- (void)removeEntry:(EntryType)entry;

- (void)removeEntryWithListIndex:(IndexType)listIndex;

- (void)removeAllEntries;

#pragma mark - Persisting Changes to the List

/**
 *  Persists the current @c entries in the receiver, if it was mutated since the last time it was saved.
 *
 *  @return Promise which resolves to @c nil after saving successfully.
 */
- (AnyPromise*)save;

@end

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
 *  Sort the receiver's entries in place with the given descriptors.
 */
- (void)sortEntriesWithDescriptors:(NSArray<NSSortDescriptor*>*)sortDesriptors;

/*
 * Indicates if the list has been mutated since the last save.
 */
@property (nonatomic, assign, readonly) BOOL dirty;

/**
 *  Subclasses must implement to support saving
 *  If unimplemented, the save method will resolve the promise with an error
 */
- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler;

@end

NS_ASSUME_NONNULL_END