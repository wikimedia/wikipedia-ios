//  Created by Monte Hurd on 11/27/13.

#import "DataContextSingleton.h"
#import "DiscoveryMethod.h"
#import "Site.h"
#import "Domain.h"

@implementation DataContextSingleton

+ (id)sharedInstance
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
        
        NSString *articlesDBPath = [[self documentRootPath] stringByAppendingString:@"/articles.sqlite"];
        NSLog(@"\n\n\ndata path: %@\n\n\n", articlesDBPath);
        NSURL *url = [NSURL fileURLWithPath:articlesDBPath];

        // First time! Will need initial data!
        BOOL needsInitialData = ([[NSFileManager defaultManager] fileExistsAtPath:articlesDBPath]) ? NO : YES;

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
        
        if (persistentStore && needsInitialData) {
            [self insertIntialData];
        }
    }
    return self;
}

- (NSString *)documentRootPath
{
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

- (void)insertIntialData
{
    // Populate discoveryMethod, site and domain tables with intial data.

//TODO: This will be updated. Temporary solution!

    NSArray *names = @[@"search", @"link", @"random"];
    for (NSString *name in names) {
        DiscoveryMethod *method = [NSEntityDescription insertNewObjectForEntityForName:@"DiscoveryMethod" inManagedObjectContext:self];
        method.name = name;
    }

    names = @[@"wikipedia.org"];
    for (NSString *name in names) {
        Site *site = [NSEntityDescription insertNewObjectForEntityForName:@"Site" inManagedObjectContext:self];
        site.name = name;
    }

    names = @[@"en"];
    for (NSString *name in names) {
        Domain *domain = [NSEntityDescription insertNewObjectForEntityForName:@"Domain" inManagedObjectContext:self];
        domain.name = name;
    }

    NSError *error = nil;
    if (![self save:&error]) {
        NSLog(@"Couldn't save: %@", [error localizedDescription]);
    }
}

@end
