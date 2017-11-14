#import "WMFArticleListAction+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListAction (CoreDataProperties)

+ (NSFetchRequest<WMFArticleListAction *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *date;
@property (nonatomic) int16_t action;
@property (nullable, nonatomic, retain) NSSet<WMFArticleList *> *lists;
@property (nullable, nonatomic, retain) NSSet<WMFArticleListEntry *> *entries;

@end

@interface WMFArticleListAction (CoreDataGeneratedAccessors)

- (void)addListsObject:(WMFArticleList *)value;
- (void)removeListsObject:(WMFArticleList *)value;
- (void)addLists:(NSSet<WMFArticleList *> *)values;
- (void)removeLists:(NSSet<WMFArticleList *> *)values;

- (void)addEntriesObject:(WMFArticleListEntry *)value;
- (void)removeEntriesObject:(WMFArticleListEntry *)value;
- (void)addEntries:(NSSet<WMFArticleListEntry *> *)values;
- (void)removeEntries:(NSSet<WMFArticleListEntry *> *)values;

@end

NS_ASSUME_NONNULL_END
