#import "WMFArticleListEntry+CoreDataProperties.h"

@implementation WMFArticleListEntry (CoreDataProperties)

+ (NSFetchRequest<WMFArticleListEntry *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticleListEntry"];
}

@dynamic order;
@dynamic id;
@dynamic project;
@dynamic title;
@dynamic created;
@dynamic updated;
@dynamic articleKey;
@dynamic list;
@dynamic actions;

@end
