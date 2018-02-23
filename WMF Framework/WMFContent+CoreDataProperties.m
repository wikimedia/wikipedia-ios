#import <WMF/WMFContent+CoreDataProperties.h>

@implementation WMFContent (CoreDataProperties)

+ (NSFetchRequest<WMFContent *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFContent"];
}

@dynamic object;
@dynamic contentGroup;

@end
