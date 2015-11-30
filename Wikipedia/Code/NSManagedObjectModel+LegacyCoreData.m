//
//  NSManagedObjectModel+LegacyCoreData.m
//  LegacyCoreData
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSManagedObjectModel+LegacyCoreData.h"

@implementation NSManagedObjectModel (LegacyCoreData)

+ (NSManagedObjectModel*)wmf_legacyCoreDataModel {
    static NSManagedObjectModel* legacyCoreDataModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        legacyCoreDataModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
        NSAssert(legacyCoreDataModel.entities.count, @"Legacy CoreData DB model shouldn't be empty!");
    });
    return legacyCoreDataModel;
}

@end
