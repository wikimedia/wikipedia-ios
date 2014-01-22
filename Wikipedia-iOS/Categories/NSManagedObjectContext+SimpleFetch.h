//  Created by Monte Hurd on 12/6/13.

#import <CoreData/CoreData.h>

@class Article;

@interface NSManagedObjectContext (SimpleFetch)

-(NSManagedObject *)getEntityForName:(NSString *)entityName withPredicateFormat:(NSString *)predicateFormat, ...;

-(NSManagedObjectID *)getArticleIDForTitle:(NSString *)title domain:(NSString *)domain;

@end
