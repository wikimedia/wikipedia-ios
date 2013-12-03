//  Created by Monte Hurd on 11/27/13.

#import <CoreData/CoreData.h>

@interface DataContextSingleton : NSManagedObjectContext

+ (id)sharedInstance;

@end
