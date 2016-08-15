

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSDateFormatter+WMFExtensions.h"
#import "WMFTestFixtureUtilities.h"
#import "MWKHistoryList.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"


@interface MWKHistoryList (WMFHistoryListPerformanceTests)

- (MWKHistoryEntry*)addEntry:(MWKHistoryEntry*)entry;

@end

@interface MWKHistoryListPerformanceTests : XCTestCase

@end

@implementation MWKHistoryListPerformanceTests

- (void)testReadPerformance {
    MWKDataStore* dataStore = [MWKDataStore temporaryDataStore];
    MWKHistoryList* list    = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    int count               = 1000;
    for (int i = 0; i < count; i++) {
        MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithURL:[NSURL wmf_randomArticleURL]];
        [list addEntry:entry];
    }

    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];

    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        [self measureBlock:^{
            [list enumerateItemsWithBlock:^(MWKHistoryEntry* _Nonnull entry, BOOL* _Nonnull stop) {
            }];
            XCTAssertEqual([list numberOfItems], count);
        }];
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
