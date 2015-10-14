
#import "MWKDataObject.h"
#import "WMFBlockDefinitions.h"

@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@protocol MWKListObject <NSObject>

- (id <NSCopying, NSObject>)listIndex;

@end

/**
 * Abstract base class for homogeneous lists of model objects.
 *
 * Can be specialized to contain instances of @c EntryType, which are queryable by index or an associated key of type
 * @c IndexType.
 */
@interface MWKList
<EntryType : id<MWKListObject>, IndexType : id<NSCopying, NSObject> > : MWKDataObject<NSFastEnumeration>
// Note: ObjC generics give uncrustify a headache: https://github.com/bengardner/uncrustify/issues/404

 - (instancetype)initWithEntries:(NSArray<EntryType>* __nullable)entries;

/**
 *  Observable - observe to get KVO notifications
 */
 @property (nonatomic, strong, readonly) NSArray<EntryType>* entries;

- (NSUInteger)countOfEntries;

- (void)addEntry:(EntryType)entry;

- (void)insertEntry:(EntryType)entry atIndex:(NSUInteger)index;

- (NSUInteger)indexForEntry:(EntryType)entry;

- (EntryType)entryAtIndex:(NSUInteger)index;

- (EntryType __nullable)entryForListIndex:(IndexType)listIndex;

- (BOOL)containsEntryForListIndex:(IndexType)listIndex;

- (void)updateEntryWithListIndex:(IndexType)listIndex update:(BOOL (^)(EntryType entry))update;

- (void)removeEntry:(EntryType)entry;

- (void)removeEntryWithListIndex:(IndexType)listIndex;

- (void)removeAllEntries;

/**
 *  Sort the receiver's entries in place with the given descriptors.
 */
- (void)sortEntriesWithDescriptors:(NSArray<NSSortDescriptor*>*)sortDesriptors;

/*
 * Indicates if the list has unsaved changes
 */
@property (nonatomic, assign, readonly) BOOL dirty;

/**
 *  Save changes.
 *
 *  @return The task. Result will be nil.
 */
- (AnyPromise*)save;


@end


@interface MWKList (Subclasses)

/**
 *  Subclasses must implement to support saving
 *  If unimplemented, the save method will resolve the promise with an error
 */
- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler;

@end

NS_ASSUME_NONNULL_END