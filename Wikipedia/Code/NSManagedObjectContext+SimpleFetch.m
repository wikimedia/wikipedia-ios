//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleCoreDataObjects.h"
#import "MWKSite.h"

@implementation NSManagedObjectContext (SimpleFetch)

- (NSManagedObject*)getEntityForName:(NSString*)entityName withPredicateFormat:(NSString*)predicateFormat, ...
{
    // See: http://www.cocoawithlove.com/2009/05/variable-argument-lists-in-cocoa.html for variadic methods syntax reminder.
    va_list args;
    va_start(args, predicateFormat);
    NSPredicate* predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
    va_end(args);

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity  = [NSEntityDescription entityForName:entityName
                                               inManagedObjectContext        :self];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];

    NSError* error    = nil;
    NSArray* entities = [self executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }

    // Return nil if no results - makes it easier to test whether any entities were found.
    if (entities) {
        return (entities.count == 1) ? entities[0] : nil;
    } else {
        return nil;
    }
}

- (NSManagedObjectID*)getArticleIDForTitle:(NSString*)title domain:(NSString*)domain {
    Article* article = (Article*)[self getEntityForName:@"Article" withPredicateFormat:@"\
                       title == %@ \
                       AND \
                       site == %@ \
                       AND \
                       domain == %@",
                                  title,
                                  WMFDefaultSiteDomain,//[SessionSingleton sharedInstance].site,
                                  domain
                       ];

    return (article) ? article.objectID : nil;
}

@end
