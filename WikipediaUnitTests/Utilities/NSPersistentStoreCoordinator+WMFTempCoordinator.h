//
//  NSPersistentStoreCoordinator+WMFTempCoordinator.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObjectModel+OldDataSchema.h"

@interface NSPersistentStoreCoordinator (WMFTempCoordinator)

+ (NSPersistentStoreCoordinator*)wmf_tempCoordinator;

@end
