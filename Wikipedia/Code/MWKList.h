
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

- (EntryType __nullable)entryForListIndex:(MWKListIndex)listIndex;

- (BOOL)containsEntryForListIndex:(MWKListIndex)listIndex;

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

NS_ASSUME_NONNULL_END