
#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectModel+LegacyCoreData.h"

@interface ArticleDataContextSingleton ()

@property (nonatomic, retain) NSManagedObjectContext* masterContext;

@end

@implementation ArticleDataContextSingleton


+ (ArticleDataContextSingleton*)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString*)databasePath {
    NSString* articlesDBPath = [[self documentRootPath] stringByAppendingString:@"/articleData6.sqlite"];
    return articlesDBPath;
}

- (NSManagedObjectContext*)masterContext {
    if (!_masterContext) {
        NSPersistentStoreCoordinator* persistentStoreCoordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel wmf_legacyCoreDataModel]];

        NSURL* url = [NSURL fileURLWithPath:[self databasePath]];

        NSDictionary* options = @{
            NSMigratePersistentStoresAutomaticallyOption: @YES,
            NSInferMappingModelAutomaticallyOption: @YES
        };
        NSError* error                     = nil;
        NSPersistentStore* persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                      configuration:nil
                                                                                                URL:url
                                                                                            options:options
                                                                                              error:&error];
        if (!persistentStore) {
            NSLog(@"Error creating persistent store coordinator: %@", error.localizedFailureReason);
            return nil;
        }

        _masterContext                            = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _masterContext.persistentStoreCoordinator = persistentStoreCoordinator;
    }

    return _masterContext;
}

- (NSManagedObjectContext*)mainContext {
    if (!_mainContext) {
        if (!self.masterContext) {
            return nil;
        }

        // Setup main context.
        _mainContext               = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.masterContext;

        // Ensure object changes saved to mainContext bubble up to masterContext.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(propagateMainSavesToMaster)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:_mainContext];
    }

    return _mainContext;
}

- (NSManagedObjectContext*)backgroundContext {
    NSManagedObjectContext* newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    newContext.parentContext = self.masterContext;

    return newContext;
}

- (NSString*)documentRootPath {
    NSArray* documentPaths     = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

- (void)saveContextAndPropagateChangesToStore:(NSManagedObjectContext*)context completionBlock:(void (^)(NSError* error))completionBlock {
    [context performBlock:^{
        __block NSError* errorToSend = nil;

        NSError* error = nil;
        if ([context save:&error]) {
            [self.masterContext performBlock:^{
                NSError* masterError = nil;
                if (![self.masterContext save:&masterError]) {
                    errorToSend = masterError;
                }
            }];
        } else {
            errorToSend = error;
        }

        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(errorToSend);
            });
        }
    }];
}

- (void)propagateMainSavesToMaster {
    [self.masterContext performBlock:^{
        NSError* masterError = nil;
        if (![self.masterContext save:&masterError]) {
            NSLog(@"Error saving to master context = %@", masterError);
        }
    }];
}

@end
