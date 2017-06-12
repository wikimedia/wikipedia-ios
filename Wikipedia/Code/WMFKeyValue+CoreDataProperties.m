#import <WMF/WMFKeyValue+CoreDataProperties.h>

@implementation WMFKeyValue (CoreDataProperties)

+ (NSFetchRequest<WMFKeyValue *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFKeyValue"];
}

@dynamic key;
@dynamic group;
@dynamic date;
@dynamic value;

@end
