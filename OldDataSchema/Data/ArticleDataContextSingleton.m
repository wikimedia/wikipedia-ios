//  Created by Monte Hurd on 11/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ArticleDataContextSingleton.h"

@interface ArticleDataContextSingleton (){
    
}

@property (nonatomic, retain) NSManagedObjectContext *masterContext;

@end

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

        [self setupMasterContext];
        
        // Setup main context.
        self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainContext.parentContext = self.masterContext;
        
        // Ensure object changes saved to mainContext bubble up to masterContext.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(propagateMainSavesToMaster)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.mainContext];
    }
    return self;
}

-(void)setupMasterContext
{
    // Setup the masterContext and attach the persistant store to it.
    self.masterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"OldDataSchemaBundle" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[bundle]];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSString *articlesDBPath = [[self documentRootPath] stringByAppendingString:@"/articleData6.sqlite"];
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
    
    self.masterContext.persistentStoreCoordinator = persistentStoreCoordinator;
}

- (NSString *)documentRootPath
{
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

- (void)propagateMainSavesToMaster{
    [self.masterContext performBlock:^{
        NSError *masterError = nil;
        if (![self.masterContext save:&masterError]) {
            NSLog(@"Error saving to master context = %@", masterError);
        }
    }];
}

@end
