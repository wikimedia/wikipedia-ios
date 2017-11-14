#import "WMFArticleListEntry+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListEntry (CoreDataProperties)

+ (NSFetchRequest<WMFArticleListEntry *> *)fetchRequest;

@property (nonatomic) int64_t order;
@property (nonatomic) int64_t id;
@property (nullable, nonatomic, copy) NSString *project;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSDate *created;
@property (nullable, nonatomic, copy) NSDate *updated;
@property (nullable, nonatomic, copy) NSString *articleKey;
@property (nullable, nonatomic, retain) WMFArticleList *list;
@property (nullable, nonatomic, retain) WMFArticleListAction *actions;

@end

NS_ASSUME_NONNULL_END
