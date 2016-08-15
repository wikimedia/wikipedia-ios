//
//  MWKHistoryListDataStoreTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataStoreListTests.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "MWKHistoryEntry+MWKRandom.h"

@interface MWKHistoryListDataStoreTests : MWKDataStoreListTests

@end

@implementation MWKHistoryListDataStoreTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
  return [MWKHistoryEntry randomSaveableEntry];
}

+ (Class)listClass {
  return [MWKHistoryList class];
}

@end
