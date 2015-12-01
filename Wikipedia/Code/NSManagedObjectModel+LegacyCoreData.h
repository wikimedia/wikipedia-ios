//
//  NSManagedObjectModel+LegacyCoreData.h
//  LegacyCoreData
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (LegacyCoreData)

+ (NSManagedObjectModel*)wmf_legacyCoreDataModel;

@end
