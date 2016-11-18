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
    NSMutableArray *randomURLs = [NSMutableArray arrayWithCapacity:1000];
    for (int i = 0; i < count; i++) {
        [randomURLs addObject:[NSURL wmf_randomArticleURL]];
    }

    [list addPagesToHistoryWithURLs:randomURLs];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        XCTAssertEqual([list numberOfItems], count);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
