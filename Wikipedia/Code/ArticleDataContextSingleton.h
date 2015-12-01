
#import <CoreData/CoreData.h>

@interface ArticleDataContextSingleton : NSObject

+ (ArticleDataContextSingleton*)sharedInstance;

/**
 *  The path to the DB
 *
 *  @return The path
 */
- (NSString*)databasePath;

/**
 *  Created lazily
 */
@property (nonatomic, retain) NSManagedObjectContext* mainContext;

/**
 *  Create a new background context. You are responsible for its lifecycle
 *  and propagating changes to the store.
 *
 *  @return A new background context
 */
- (NSManagedObjectContext*)backgroundContext;

/**
 *  Automatically propagates changes to the store.
 *  Use this for background contexts to handle the save propagation for you.
 *
 *  @param context         The context to save
 *  @param completionBlock a completion block fired after the save operation
 */
- (void)saveContextAndPropagateChangesToStore:(NSManagedObjectContext*)context completionBlock:(void (^)(NSError* error))completionBlock;

@end
