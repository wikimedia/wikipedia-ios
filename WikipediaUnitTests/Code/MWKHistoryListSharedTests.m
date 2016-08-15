//
//  MWKHistoryListAppendingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListSharedTests.h"
#import "MWKHistoryEntry+MWKRandom.h"

@interface MWKHistoryListSharedTests : MWKListSharedTests

@end

@implementation MWKHistoryListSharedTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
  return [MWKHistoryEntry random];
}

+ (Class)listClass {
  return [MWKHistoryList class];
}

@end
