
#import "MWKList+Subclass.h"
#import "Wikipedia-Swift.h"

@interface MWKList ()

@property (nonatomic, strong) NSMutableArray<id<MWKListObject> >* mutableEntries;
@property (nonatomic, readwrite, assign) BOOL dirty;

@end


@implementation MWKList

#pragma mark - Setup

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableEntries = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithEntries:(NSArray* __nullable)entries {
    self = [self init];
    if (self) {
        [self importEntries:entries];
        [self sortEntries];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[self class]]) {
        return WMF_EQUAL(self.entries, isEqualToArray:, [(MWKList*)object entries]);
    } else {
        return NO;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.entries];
}

#pragma mark - Import

- (void)importEntries:(NSArray*)entries {
    [self.mutableEntries setArray:entries];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len {
    return [self.entries countByEnumeratingWithState:state objects:stackbuf count:len];
}

#pragma mark - Entry Access

- (NSArray*)entries {
    return _mutableEntries;
}

- (void)addEntry:(id<MWKListObject>)entry {
    NSAssert([entry conformsToProtocol:@protocol(MWKListObject)], @"attempting to add object that does not implement MWKListObject");
    [self.mutableEntries addObject:entry];
    [self sortEntries];
    self.dirty = YES;
}

- (void)insertEntry:(id<MWKListObject>)entry atIndex:(NSUInteger)index {
    NSAssert([entry conformsToProtocol:@protocol(MWKListObject)], @"attempting to insert object that does not implement MWKListObject");
    [self.mutableEntries insertObject:entry atIndex:index];
    [self sortEntries];
    self.dirty = YES;
}

- (NSUInteger)indexForEntry:(id<MWKListObject>)entry {
    return [self.mutableEntries indexOfObject:entry];
}

- (id<MWKListObject>)entryAtIndex:(NSUInteger)index {
    return (id<MWKListObject>)[self objectInEntriesAtIndex : index];
}

- (id<MWKListObject> __nullable)entryForListIndex:(MWKListIndex)listIndex {
    return [self.entries bk_match:^BOOL (id < MWKListObject > obj) {
        if ([[obj listIndex] isEqual:listIndex]) {
            return YES;
        }
        return NO;
    }];
}

- (BOOL)containsEntryForListIndex:(MWKListIndex)listIndex {
    id<MWKListObject> entry = [self entryForListIndex:listIndex];
    return (entry != nil);
}

- (void)updateEntryWithListIndex:(id)listIndex update:(BOOL (^)(id<MWKListObject> entry))update {
    id<MWKListObject> obj = [self entryForListIndex:listIndex];
    if (update) {
        BOOL dirty = update(obj);
        if (dirty) {
            [self sortEntries];
            self.dirty = YES;
        }
    }
}

- (void)removeEntry:(id<MWKListObject>)entry {
    [self.mutableEntries removeObject:entry];
    self.dirty = YES;
}

- (void)removeEntryWithListIndex:(id)listIndex {
    id<MWKListObject> obj = [self entryForListIndex:listIndex];
    if (obj) {
        [self removeEntry:obj];
    }
}

- (void)removeAllEntries {
    [self.mutableEntries removeAllObjects];
    self.dirty = YES;
}

- (void)sortEntries {
    if ([[self sortDescriptors] count] > 0) {
        [self.mutableEntries sortUsingDescriptors:[self sortDescriptors]];
    }
}

- (nullable NSArray<NSSortDescriptor*>*)sortDescriptors {
    return nil;
}

#pragma mark - Save

- (AnyPromise*)save {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatchOnMainQueue(^{
            if (self.dirty) {
                [self performSaveWithCompletion:^{
                    self.dirty = NO;
                    resolve(nil);
                } error:^(NSError* error){
                    resolve(error);
                }];
            } else {
                self.dirty = NO;
                resolve(nil);
            }
        });
    }];
}

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    if (errorHandler) {
        errorHandler([NSError wmf_unableToSaveErrorWithReason:@"Save is unimplemented for this list"]);
    }
}

#pragma mark - KVO

- (NSMutableArray*)mutableEntries {
    return [self mutableArrayValueForKey:WMF_SAFE_KEYPATH(self, entries)];
}

- (NSUInteger)countOfEntries {
    return [_mutableEntries count];
}

- (id)objectInEntriesAtIndex:(NSUInteger)idx {
    return [_mutableEntries objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inEntriesAtIndex:(NSUInteger)idx {
    [_mutableEntries insertObject:anObject atIndex:idx];
}

- (void)insertEntries:(NSArray*)entrieArray atIndexes:(NSIndexSet*)indexes {
    [_mutableEntries insertObjects:entrieArray atIndexes:indexes];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
    [_mutableEntries removeObjectAtIndex:idx];
}

- (void)removeEntriesAtIndexes:(NSIndexSet*)indexes {
    [_mutableEntries removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(id)anObject {
    [_mutableEntries replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceEntriesAtIndexes:(NSIndexSet*)indexes withEntries:(NSArray*)entrieArray {
    [_mutableEntries replaceObjectsAtIndexes:indexes withObjects:entrieArray];
}

@end
