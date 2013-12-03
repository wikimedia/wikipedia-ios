//
//  Domain.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/3/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article;

@interface Domain : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *article;
@end

@interface Domain (CoreDataGeneratedAccessors)

- (void)addArticleObject:(Article *)value;
- (void)removeArticleObject:(Article *)value;
- (void)addArticle:(NSSet *)values;
- (void)removeArticle:(NSSet *)values;

@end
