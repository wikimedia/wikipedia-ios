//  Created by Monte Hurd on 11/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <CoreData/CoreData.h>

@interface ArticleDataContextSingleton : NSObject

+ (ArticleDataContextSingleton *)sharedInstance;

@property (nonatomic, retain) NSManagedObjectContext *mainContext;

@end
