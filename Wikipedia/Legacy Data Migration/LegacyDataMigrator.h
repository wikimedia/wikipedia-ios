//
//  LegacyDataMigrator.h
//  Wikipedia
//
//  Created by Brion on 12/29/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LegacyCoreDataMigrator.h"

#import "MediaWikiKit.h"

@interface LegacyDataMigrator : NSObject <LegacyCoreDataDelegate>

@property (nonatomic, strong) LegacyCoreDataMigrator* schema;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKUserDataStore* userDataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

@end
