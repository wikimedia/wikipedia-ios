//
//  NSPersistentStoreCoordinator+WMFTempCoordinator.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSPersistentStoreCoordinator+WMFTempCoordinator.h"
#import "NSManagedObjectModel+OldDataSchema.h"
#import "WMFRandomFileUtilities.h"

@implementation NSPersistentStoreCoordinator (WMFTempCoordinator)

+ (NSPersistentStoreCoordinator*)wmf_tempCoordinator {
    NSPersistentStoreCoordinator *persistentStoreCoordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel wmf_oldDataSchema]];

    NSError *error = nil;
    NSPersistentStore* persistentStore =
        [persistentStoreCoordinator
         addPersistentStoreWithType:NSSQLiteStoreType
                      configuration:nil
                                URL:[NSURL fileURLWithPath:WMFRandomTemporaryFileOfType(@"sqlite")]
                            options:nil
                              error:&error];
    NSParameterAssert(!error && persistentStore);
    return persistentStoreCoordinator;
}

@end
