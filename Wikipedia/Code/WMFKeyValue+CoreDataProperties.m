#import "WMFKeyValue+CoreDataProperties.h"

@implementation WMFKeyValue (CoreDataProperties)

+ (NSFetchRequest<WMFKeyValue *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WMFKeyValue"];
}

@dynamic key;
@dynamic date;
@dynamic value;

@end
