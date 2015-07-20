#import "MWKTestCase.h"

@interface MWKListTestClass : NSObject<MWKListObject>

@property (nonatomic, strong) NSString* itemID;

@end

@implementation MWKListTestClass

- (id<NSCopying>)listIndex {
    if (!self.itemID) {
        self.itemID = [[NSUUID UUID] UUIDString];
    }
    return self.itemID;
}

@end

@interface MWKListTests : MWKTestCase

@property (nonatomic, strong) NSArray* testObjects;

@end

@implementation MWKListTests

- (void)setUp {
    [super setUp];

    NSMutableArray* array = [NSMutableArray array];

    for (int i = 0; i < 10; i++) {
        [array addObject:[MWKListTestClass new]];
    }

    self.testObjects = array;
}

- (void)tearDown {
    self.testObjects = nil;
    [super tearDown];
}

- (void)testEmptyCount {
    MWKList* list = [[MWKList alloc] init];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 initially");
}

- (void)testInit {
    MWKList* list = [[MWKList alloc] initWithEntries:self.testObjects];
    XCTAssertEqual([list countOfEntries], [self.testObjects count], @"Should have equal length ");
}

- (void)testAddCount {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:[self.testObjects firstObject]];
    XCTAssertEqual([list countOfEntries], 1, @"Should have length 1 after adding");
}

- (void)testContains {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:[self.testObjects firstObject]];
    XCTAssertTrue([list containsEntryForListIndex:[[self.testObjects firstObject] listIndex]], @"Should contain after adding");
}

- (void)testAddToEnd {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    XCTAssertEqual([list entryAtIndex:3], self.testObjects[3], @"Last entry should be at end");
}

- (void)testInsert {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    [list insertEntry:self.testObjects[4] atIndex:2];
    XCTAssertEqual([list entryAtIndex:2], self.testObjects[4], @"Inserted entry should be at index 2");
}

- (void)testInsertNotEqual {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    [list insertEntry:self.testObjects[4] atIndex:2];
    XCTAssertNotEqual([list entryAtIndex:3], self.testObjects[4], @"Inserted entry should not be at index 3");
}

- (void)testAddCount2 {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    XCTAssertEqual([list countOfEntries], 2, @"Should have length 2 after adding");
}

- (void)testEmptyNotDirty {
    MWKList* list = [[MWKList alloc] init];
    XCTAssertFalse(list.dirty, @"Should not be dirty initially");
}

- (void)testEmptyDirtyAfterAdd {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    XCTAssertTrue(list.dirty, @"Should be dirty after adding");
}

- (void)testAddThenRemove {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 after adding two then removing 1");
}

- (void)testAddThenRemoveByListIndex {
    MWKList* list = [[MWKList alloc] init];
    [list addEntry:self.testObjects[0]];
    [list removeEntryWithListIndex:[self.testObjects[0] listIndex]];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 after adding two then removing 1");
}

- (void)testRemoveAll {
    MWKList* list = [[MWKList alloc] initWithEntries:self.testObjects];
    [list removeAllEntries];
    XCTAssertEqual([list countOfEntries], 0, @"Should have length 0 after removing all");
}

- (void)testKVO {
    MWKList* list                = [[MWKList alloc] init];
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
