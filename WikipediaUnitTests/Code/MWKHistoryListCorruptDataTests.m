#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListCorruptDataTests : XCTestCase
@property (strong, nonatomic) MWKHistoryList *historyList;

@end

@implementation MWKHistoryListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyTitles {
    MWKDataStore *dataStore = [MWKDataStore temporaryDataStore];
    MWKHistoryList *list = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    [list addPageToHistoryWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"]];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        assertThat(@([list numberOfItems]), is(@1));
        [list addPageToHistoryWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];
        [dataStore notifyWhenWriteTransactionsComplete:^{
            assertThat(@([list numberOfItems]), is(@1));
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

#pragma clang diagnostic pop

@end
