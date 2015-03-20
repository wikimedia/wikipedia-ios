//  Created by Monte Hurd on 11/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <CoreData/CoreData.h>

@interface ArticleDataContextSingleton : NSObject

@property (nonatomic, retain) NSManagedObjectContext *mainContext;

+ (ArticleDataContextSingleton *)sharedInstance;

- (id)createArticleDataModel:(Class)modelClass;

@end
