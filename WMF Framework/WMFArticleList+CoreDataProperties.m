#import "WMFArticleList+CoreDataProperties.h"

@implementation WMFArticleList (CoreDataProperties)

+ (NSFetchRequest<WMFArticleList *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticleList"];
}

@dynamic created;
@dynamic id;
@dynamic listDescription;
@dynamic name;
@dynamic order;
@dynamic updated;
@dynamic color;
@dynamic image;
@dynamic entries;
@dynamic actions;

@end
