//
//  MWKListBaseTests.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import XCTest;

@interface MWKListTestBase : XCTestCase

@property (nonatomic, strong) NSArray* testObjects;

+ (id)uniqueListEntry;

+ (Class)listClass;

- (MWKList*)listWithEntries:(NSArray*)entries;

@end

@interface MWKListDummyEntry : NSObject<MWKListObject>

@property (nonatomic, strong) NSString* listIndex;

@end
