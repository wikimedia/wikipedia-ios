//
//  NSManagedObject+WMFModelFactory.h
//  OldDataSchema
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (WMFModelFactory)

+ (NSString*)wmf_entityName;

+ (instancetype)wmf_newWithContext:(NSManagedObjectContext*)context;

@end
