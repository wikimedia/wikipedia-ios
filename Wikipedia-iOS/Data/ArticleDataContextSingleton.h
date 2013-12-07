//  Created by Monte Hurd on 11/27/13.

#import <CoreData/CoreData.h>

@interface ArticleDataContextSingleton : NSManagedObjectContext

+ (ArticleDataContextSingleton *)sharedInstance;

@end
