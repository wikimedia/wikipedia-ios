//
//  SchemaConverter.h
//  Wikipedia
//
//  Created by Brion on 12/29/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OldDataSchema.h"

#import "MediaWikiKit.h"

@interface SchemaConverter : NSObject <OldDataSchemaDelegate>

@property OldDataSchema *schema;
@property MWKDataStore *dataStore;
@property MWKUserDataStore *userDataStore;

-(instancetype)initWithDataStore:(MWKDataStore *)dataStore;

@end
