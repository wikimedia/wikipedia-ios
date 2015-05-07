//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <CoreData/CoreData.h>

@class Article;

@interface NSManagedObjectContext (SimpleFetch)

- (NSManagedObject*)getEntityForName:(NSString*)entityName withPredicateFormat:(NSString*)predicateFormat, ...;

- (NSManagedObjectID*)getArticleIDForTitle:(NSString*)title domain:(NSString*)domain;

@end
