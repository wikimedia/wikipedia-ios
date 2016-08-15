//
//  MWKRecentSearchesSharedTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListSharedTests.h"
#import "MWKRecentSearchList.h"
#import "MWKRecentSearchEntry.h"

@interface MWKRecentSearchesSharedTests : MWKListSharedTests

@end

@implementation MWKRecentSearchesSharedTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
    return [[MWKRecentSearchEntry alloc] initWithURL:[NSURL wmf_randomSiteURL] searchTerm:[[NSUUID UUID] UUIDString]];
}

+ (Class)listClass {
    return [MWKRecentSearchList class];
}

@end
