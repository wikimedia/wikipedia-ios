//
//  NSManagedObject+WMFModelFactory.m
//  OldDataSchema
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSManagedObject+WMFModelFactory.h"

@implementation NSManagedObject (WMFModelFactory)

+ (NSString*)wmf_entityName {
    return NSStringFromClass(self);
}

+ (instancetype)wmf_newWithContext:(NSManagedObjectContext *)context {
    return [[self alloc]
            initWithEntity:[NSEntityDescription entityForName:[self wmf_entityName] inManagedObjectContext:context]
            insertIntoManagedObjectContext:context];
}

@end
