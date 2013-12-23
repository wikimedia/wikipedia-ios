//  Created by Monte Hurd on 12/6/13.

#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleCoreDataObjects.h"
#import "SessionSingleton.h"

@implementation NSManagedObjectContext (SimpleFetch)

-(NSArray *)getEntitiesForName:(NSString *)entityName withPredicateFormat:(NSString *)predicateFormat, ...
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
    NSArray *entities = [self executeFetchRequest:fetchRequest error:&error];

    // Return nil if no results - makes it easier to test whether any entities were found.
    if (entities && (entities.count == 0)) entities = nil;

    if(error != nil){
        NSLog(@"Error: %@", error);
        return nil;
    }
    return entities;
}

//NSManagedObject *entity = (NSManagedObject *)entities[0];

-(NSManagedObjectID *)getArticleIDForTitle:(NSString *)title
{
    NSArray *articles = [self getEntitiesForName: @"Article" withPredicateFormat: @"\
                       title ==[c] %@ \
                       AND \
                       site.name == %@ \
                       AND \
                       domain.name == %@",
                       title,
                       [SessionSingleton sharedInstance].site,
                       [SessionSingleton sharedInstance].domain
    ];

    Article *article = (articles) ? (Article *)articles[0] : nil;

    if (!article) {
        article = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:self];
        article.title = title;
        article.dateCreated = [NSDate date];
        article.site = [SessionSingleton sharedInstance].site;
        article.domain = [SessionSingleton sharedInstance].domain;
    }
    return article.objectID;
}

@end
