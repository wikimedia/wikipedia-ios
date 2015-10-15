//
//  MWKDataStoreListTests.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListTestBase.h"

@class MWKDataStore;

/**
 *  Shared tests for persisting @c MWKList subclasses which conform to @c MWKDataStoreList
 */
@interface MWKDataStoreListTests : MWKListTestBase

/// Temporary data store which is setup & torn down between tests.
@property (nonatomic, strong) MWKDataStore* tempDataStore;

@end
