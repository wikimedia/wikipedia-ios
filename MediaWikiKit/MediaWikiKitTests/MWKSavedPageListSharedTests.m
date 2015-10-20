//
//  MWKSavedPageListSharedTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListSharedTests.h"

@interface MWKSavedPageListSharedTests : MWKListSharedTests

@end

@implementation MWKSavedPageListSharedTests

+ (Class)listClass {
    return [MWKSavedPageList class];
}

+ (id)uniqueListEntry {
    return [[MWKSavedPageEntry alloc] initWithTitle:[MWKTitle random]];
}

@end
