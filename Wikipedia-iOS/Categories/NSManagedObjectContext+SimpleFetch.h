//  Created by Monte Hurd on 12/6/13.

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (SimpleFetch)

-(NSManagedObject *)getEntityForName:(NSString *)entityName withPredicateFormat:(NSString *)predicateFormat, ...;

@end
