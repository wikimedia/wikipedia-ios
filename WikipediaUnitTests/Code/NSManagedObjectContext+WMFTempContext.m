//
//  NSManagedObjectContext+WMFTempContext.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSManagedObjectContext+WMFTempContext.h"
#import "NSPersistentStoreCoordinator+WMFTempCoordinator.h"

@implementation NSManagedObjectContext (WMFTempContext)

+ (instancetype)wmf_tempContext {
    NSManagedObjectContext* ctxt = [NSManagedObjectContext new];
    ctxt.persistentStoreCoordinator = [NSPersistentStoreCoordinator wmf_tempCoordinator];
    return ctxt;
}

@end
