#import "WMFArticleListAction+CoreDataProperties.h"

@implementation WMFArticleListAction (CoreDataProperties)

+ (NSFetchRequest<WMFArticleListAction *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticleListAction"];
}

@dynamic date;
@dynamic action;
@dynamic lists;
@dynamic entries;

@end
