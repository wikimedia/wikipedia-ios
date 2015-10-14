//
//  MWKHistoryListAppendingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListSharedTests.h"

@interface MWKHistoryListSharedTests : MWKListSharedTests

@end

@implementation MWKHistoryListSharedTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
    MWKTitle* randomTitle =
    [[MWKTitle alloc] initWithURL:
    [NSURL URLWithString:
     [NSString stringWithFormat:@"https://en.wikipedia.org/wiki/%@", [[NSUUID UUID] UUIDString]]]];
    MWKHistoryDiscoveryMethod randomDiscoveryMethod = arc4random() % 7;
    return [[MWKHistoryEntry alloc] initWithTitle:randomTitle discoveryMethod:randomDiscoveryMethod];
}

+ (Class)listClass {
    return [MWKHistoryList class];
}

@end
