
#import "MWKDataObject.h"
@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@protocol MWKListObject <NSObject>

- (id <NSCopying>)listIndex;

@end

@interface MWKList : MWKDataObject<NSFastEnumeration>

- (instancetype)initWithEntries:(NSArray* __nullable)entries;

/**
 *  Observable - observe to get KVO notifications
 */
@property (nonatomic, strong, readonly)  NSArray* entries;

- (NSUInteger)countOfEntries;

- (void)addEntry:(id<MWKListObject>)entry;

- (void)insertEntry:(id<MWKListObject>)entry atIndex:(NSUInteger)index;

- (NSUInteger)indexForEntry:(id<MWKListObject>)entry;

- (id<MWKListObject>)entryAtIndex:(NSUInteger)index;

- (id<MWKListObject> __nullable)entryForListIndex:(id <NSCopying>)listIndex;

- (BOOL)containsEntryForListIndex:(id <NSCopying>)listIndex;

- (void)updateEntryWithListIndex:(id <NSCopying>)listIndex update:(BOOL (^)(id<MWKListObject> __nullable entry))update;

- (void)removeEntry:(id<MWKListObject>)entry;

- (void)removeEntryWithListIndex:(id <NSCopying>)listIndex;

- (void)removeAllEntries;

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