//  Created by Monte Hurd on 12/6/13.

#import <CoreData/CoreData.h>

@class Article;

@interface NSManagedObjectContext (SimpleFetch)

-(NSArray *)getEntitiesForName:(NSString *)entityName withPredicateFormat:(NSString *)predicateFormat, ...;

-(NSManagedObjectID *)getArticleIDForTitle:(NSString *)title;

@end
