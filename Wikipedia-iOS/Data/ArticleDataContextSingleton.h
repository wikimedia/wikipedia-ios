//  Created by Monte Hurd on 11/27/13.

#import <CoreData/CoreData.h>

@interface ArticleDataContextSingleton : NSObject

+ (ArticleDataContextSingleton *)sharedInstance;

// For reasoning behind masterContext, mainContext and workerContext, see
// pattern details here: http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack
// Note: masterContext is private intentionally.

@property (nonatomic, retain) NSManagedObjectContext *mainContext;

@property (nonatomic, retain) NSManagedObjectContext *workerContext;

@end
