//
//  NSManagedObjectModel+OldDataSchema.m
//  OldDataSchema
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSManagedObjectModel+OldDataSchema.h"

@implementation NSManagedObjectModel (OldDataSchema)

+ (NSManagedObjectModel*)wmf_oldDataSchema {
    static NSManagedObjectModel* oldDataSchema;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"OldDataSchemaBundle" ofType:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        oldDataSchema = [NSManagedObjectModel mergedModelFromBundles:@[bundle]];
    });
    return oldDataSchema;
}

@end
