#import "MWKDataStoreListTests.h"
#import "MWKList+Subclass.h"
#import "MWKDataStore.h"
#import "MWKDataStoreList.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

@implementation MWKDataStoreListTests

- (void)setUp {
    [super setUp];
    self.tempDataStore = [MWKDataStore temporaryDataStore];
}

- (void)tearDown {
    [self.tempDataStore removeFolderAtBasePath];
    [super tearDown];
}

+ (NSArray<NSInvocation *> *)testInvocations {
    return self == [MWKDataStoreListTests class] ? @[] : [super testInvocations];
}

- (MWKList<MWKDataStoreList> *)listWithDataStore {
    Class listClass = [[self class] listClass];
    NSAssert([listClass conformsToProtocol:@protocol(MWKDataStoreList)],
             @"listClass %@ must conform to MWKDataStoreList to run MWKDataStoreListTests.",
             listClass);
    return [[listClass alloc] initWithDataStore:self.tempDataStore];
}

- (void)testSavedListIsEqualToListWithAddedEntries {
    [self verifyListRoundTripAfter:^(MWKList *list) {
        for (id entry in self.testObjects) {
            [list addEntry:entry];
        }
    }];
}

- (void)testSavedListIsEqualToListWithAddedAndRemovedEntries {
    [self verifyListRoundTripAfter:^(MWKList *list) {
        [list removeEntryWithListIndex:[self.testObjects.firstObject listIndex]];
        [list removeEntryWithListIndex:[self.testObjects.lastObject listIndex]];
    }];
}

#pragma mark - Utils

- (void)verifyListRoundTripAfter:(void (^)(MWKList *))mutatingBlock {
    MWKList *list = [self listWithDataStore];

    mutatingBlock(list);

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [list saveWithFailure:^(NSError *error) {
        XCTFail(@"Save failed");
    }
        success:^{
            [promiseExpectation fulfill];
        }];
    WaitForExpectations();

    MWKList *otherList = [self listWithDataStore];

    [self verifyList:list isEqualToList:otherList];
}

- (void)verifyList:(MWKList *)list isEqualToList:(MWKList *)otherList {
    XCTAssert([otherList isEqual:list]);
}

@end
