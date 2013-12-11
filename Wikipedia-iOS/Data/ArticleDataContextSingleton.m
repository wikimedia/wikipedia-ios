//  Created by Monte Hurd on 11/27/13.

#import "ArticleDataContextSingleton.h"

@implementation ArticleDataContextSingleton

+ (ArticleDataContextSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSString *articlesDBPath = [[self documentRootPath] stringByAppendingString:@"/articleData.sqlite"];
        NSLog(@"\n\n\nArticle data path: %@\n\n\n", articlesDBPath);
        NSURL *url = [NSURL fileURLWithPath:articlesDBPath];

        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES
                                  };
        NSError *error = nil;
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL:url options:options error:&error];
        if (persistentStore) {
            NSLog(@"Created persistent store.");
        } else {
            NSLog(@"Error creating persistent store coordinator: %@", error.localizedFailureReason);
        }
        
        self.persistentStoreCoordinator = persistentStoreCoordinator;
        
    }
    return self;
}

- (NSString *)documentRootPath
{
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

@end
