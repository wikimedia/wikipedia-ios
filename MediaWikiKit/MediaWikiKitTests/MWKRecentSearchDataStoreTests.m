//
//  MWKRecentSearchDataStoreTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MWKRecentSearchList.h"
#import "MWKRecentSearchEntry.h"
#import "MWKDataStoreListTests.h"

@interface MWKRecentSearchDataStoreTests : MWKDataStoreListTests

@end

@implementation MWKRecentSearchDataStoreTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
    return [[MWKRecentSearchEntry alloc] initWithSite:[MWKSite random] searchTerm:[[NSUUID UUID] UUIDString]];
}

+ (Class)listClass {
    return [MWKRecentSearchList class];
}

@end
