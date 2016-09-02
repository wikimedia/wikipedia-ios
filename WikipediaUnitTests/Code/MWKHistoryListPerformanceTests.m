#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSDateFormatter+WMFExtensions.h"
#import "WMFTestFixtureUtilities.h"
#import "MWKHistoryList.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

@interface MWKHistoryListPerformanceTests : XCTestCase

@end

@implementation MWKHistoryListPerformanceTests

- (void)testReadPerformance {
    MWKDataStore *dataStore = [MWKDataStore temporaryDataStore];
    MWKHistoryList *list = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    int count = 1000;
    for (int i = 0; i < count; i++) {
        [list addPageToHistoryWithURL:[NSURL wmf_randomArticleURL]];
    }

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        XCTAssertEqual([list numberOfItems], count);
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
