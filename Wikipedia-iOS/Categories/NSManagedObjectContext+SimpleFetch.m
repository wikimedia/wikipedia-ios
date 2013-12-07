//  Created by Monte Hurd on 12/6/13.

#import "NSManagedObjectContext+SimpleFetch.h"

@implementation NSManagedObjectContext (SimpleFetch)

-(NSManagedObject *)getEntityForName:(NSString *)entityName withPredicateFormat:(NSString *)predicateFormat, ...
{
    // See: http://www.cocoawithlove.com/2009/05/variable-argument-lists-in-cocoa.html for variadic methods syntax reminder.
    va_list args;
    va_start(args, predicateFormat);
    NSPredicate * predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
    va_end(args);

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: self];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];

    NSError *error = nil;
    NSArray *methods = [self executeFetchRequest:fetchRequest error:&error];
    if(error != nil){
        NSLog(@"Error: %@", error);
        return nil;
    }

    if (methods.count == 1) {

//TODO: this assumes value is unique, otherwise nothing is returned. Probably not what's wanted in all cases.

        NSManagedObject *method = (NSManagedObject *)methods[0];
        return method;
    }else{
        return nil;
    }
}

@end
