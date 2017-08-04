#import "MWKListSharedTests.h"
#import "NSArray+WMFMatching.h"

@implementation MWKListSharedTests

#pragma mark - Lifecycle

- (void)testEmptyWhenInitializedWithNilEntries {
    MWKList *list = [self listWithEntries:nil];
    XCTAssertEqual(list.entries.count, 0);
    XCTAssertEqual(list.countOfEntries, 0);
    XCTAssertFalse(list.dirty);
}

- (void)testContainsAllUniqueEntriesPassedToInit {
    MWKList *list = [self listWithEntries:self.testObjects];
    XCTAssertEqual(list.entries.count, self.testObjects.count);
    XCTAssert([list.entries wmf_containsObjectsInAnyOrder:self.testObjects]);
    XCTAssertFalse(list.dirty);
}

#pragma mark - Mutation

- (void)testContainsAddedEntry {
    MWKList *list = [self listWithEntries:nil];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list addEntry:firstEntry];
    XCTAssertEqualObjects([list entryAtIndex:0], firstEntry);
    XCTAssertEqualObjects([list entryForListIndex:[firstEntry listIndex]], firstEntry);
    XCTAssert([list containsEntryForListIndex:[firstEntry listIndex]]);
    XCTAssert(list.dirty);
}

- (void)testDoesNotContainRemovedEntries {
    MWKList *list = [self listWithEntries:self.testObjects];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list removeEntryWithListIndex:[firstEntry listIndex]];
    XCTAssertFalse([list containsEntryForListIndex:[firstEntry listIndex]]);
    XCTAssertEqual([list entryForListIndex:[firstEntry listIndex]], nil);
    XCTAssert(list.dirty);
}

- (void)testIsEmptyAfterRemovingAllEntries {
    MWKList *list = [self listWithEntries:self.testObjects];
    [list removeAllEntries];
    XCTAssertEqual(list.entries.count, 0);
    XCTAssertEqual(list.countOfEntries, 0);
    XCTAssert(list.dirty);
}

- (void)testContainsAllUniqueAddedEntries {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];

    XCTAssertTrue([list.entries wmf_containsObjectsInAnyOrder:[self.testObjects subarrayWithRange:NSMakeRange(0, 4)]]);
}

- (void)testAddThenRemove {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];
    XCTAssertEqual(list.entries.count, 0);
    XCTAssert(list.dirty);
}

- (void)testAddThenRemoveByListIndex {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntryWithListIndex:[self.testObjects[0] listIndex]];
    XCTAssertEqual(list.entries.count, 0);
    XCTAssert(list.dirty);
}

@end
