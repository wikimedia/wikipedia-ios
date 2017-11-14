#import "WMFArticleList+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleList (CoreDataProperties)

+ (NSFetchRequest<WMFArticleList *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *created;
@property (nonatomic) int64_t id;
@property (nullable, nonatomic, copy) NSString *listDescription;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int64_t order;
@property (nullable, nonatomic, copy) NSDate *updated;
@property (nullable, nonatomic, copy) NSString *color;
@property (nullable, nonatomic, copy) NSString *image;
@property (nullable, nonatomic, retain) NSOrderedSet<WMFArticleListEntry *> *entries;
@property (nullable, nonatomic, retain) NSSet<WMFArticleListAction *> *actions;

@end

@interface WMFArticleList (CoreDataGeneratedAccessors)

- (void)insertObject:(WMFArticleListEntry *)value inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
- (void)insertEntries:(NSArray<WMFArticleListEntry *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(WMFArticleListEntry *)value;
- (void)replaceEntriesAtIndexes:(NSIndexSet *)indexes withEntries:(NSArray<WMFArticleListEntry *> *)values;
- (void)addEntriesObject:(WMFArticleListEntry *)value;
- (void)removeEntriesObject:(WMFArticleListEntry *)value;
- (void)addEntries:(NSOrderedSet<WMFArticleListEntry *> *)values;
- (void)removeEntries:(NSOrderedSet<WMFArticleListEntry *> *)values;

- (void)addActionsObject:(WMFArticleListAction *)value;
- (void)removeActionsObject:(WMFArticleListAction *)value;
- (void)addActions:(NSSet<WMFArticleListAction *> *)values;
- (void)removeActions:(NSSet<WMFArticleListAction *> *)values;

@end

NS_ASSUME_NONNULL_END
