#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListCorruptDataTests : XCTestCase

@end

@implementation MWKSavedPageListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKDataStore *dataStore = [MWKDataStore temporaryDataStore];
    MWKSavedPageList *list = [[MWKSavedPageList alloc] initWithDataStore:dataStore];
    [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"]];
    [list addSavedPageWithURL:nil];
    [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{

        assertThat(@([list numberOfItems]), is(@1));
        [expectation fulfill];

    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

#pragma clang diagnostic pop

@end
