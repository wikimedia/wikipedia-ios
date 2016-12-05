#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

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

    XCTAssertEqual([list numberOfItems], 1);
    [list addPageToHistoryWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];
    XCTAssertEqual([list numberOfItems], 1);
}

#pragma clang diagnostic pop

@end
