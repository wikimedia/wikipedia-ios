#import "MWKListAppendingTests.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"

@implementation MWKListAppendingTests

- (void)testAddToEnd {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    XCTAssertEqual([list entryAtIndex:3], self.testObjects[3], @"Last entry should be at end");
}

- (void)testInsert {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    [list insertEntry:self.testObjects[4] atIndex:2];
    XCTAssertEqual([list entryAtIndex:2], self.testObjects[4], @"Inserted entry should be at index 2");
}

- (void)testInsertNotEqual {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    [list insertEntry:self.testObjects[4] atIndex:2];
    XCTAssertNotEqual([list entryAtIndex:3], self.testObjects[4], @"Inserted entry should not be at index 3");
}

- (void)testAddCount2 {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    XCTAssertEqual([list countOfEntries], 2, @"Should have length 2 after adding");
}

- (void)testAddThenRemove {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 after adding two then removing 1");
}

- (void)testAddThenRemoveByListIndex {
    MWKList* list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntryWithListIndex:[self.testObjects[0] listIndex]];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 after adding two then removing 1");
}

- (void)testKVO {
    MWKList* list                = [self listWithEntries:nil];
    NSMutableArray* observations = [NSMutableArray new];
    [self.KVOController observe:list
                        keyPath:WMF_SAFE_KEYPATH(list, entries)
                        options:0
                          block:^(id observer, id object, NSDictionary* change) {
        [observations addObject:@[change[NSKeyValueChangeKindKey], change[NSKeyValueChangeIndexesKey]]];
    }];
    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];
    XCTAssertEqual(observations.count, 2);
    XCTAssertEqualObjects(observations[0], (@[@(NSKeyValueChangeInsertion), [NSIndexSet indexSetWithIndex:0]]));
    XCTAssertEqualObjects(observations[1], (@[@(NSKeyValueChangeRemoval), [NSIndexSet indexSetWithIndex:0]]));
    [self.KVOController unobserve:list];
}

@end
