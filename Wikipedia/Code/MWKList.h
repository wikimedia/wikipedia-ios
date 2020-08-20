#import <WMF/WMFMTLModel.h>
#import <WMF/MWKDataObject.h>
#import <WMF/WMFBlockDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MWKListObject <NSObject>

- (id<NSCopying, NSObject>)listIndex;

@end

typedef id<MWKListObject> MWKListEntry;
typedef id<NSCopying, NSObject> MWKListIndex;

/**
 * Abstract base class for homogeneous lists of model objects.
 *
 * Can be specialized to contain instances of @c EntryType, which are queryable by index or an associated key of type
 * @c IndexType.
 */
@interface MWKList <EntryType : MWKListEntry, IndexType : MWKListIndex> : WMFMTLModel<NSFastEnumeration>

 - (instancetype)initWithEntries:(NSArray<EntryType>* __nullable)entries;

/**
 *  Observable - observe to get KVO notifications
 */
@property (nonatomic, strong, readonly) NSArray<EntryType> *entries;

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

- (NSArray *)pruneToMaximumCount:(NSUInteger)maximumCount;

#pragma mark - Persisting Changes to the List

- (void)saveWithFailure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;
- (void)save;

@end

NS_ASSUME_NONNULL_END
