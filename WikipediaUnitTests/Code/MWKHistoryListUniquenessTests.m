#import "MWKTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

@interface MWKHistoryListUniquenessTests : MWKTestCase

@end

@implementation MWKHistoryListUniquenessTests {
    NSURL *siteURLEn;
    NSURL *siteURLFr;
    NSURL *titleURLSFEn;
    NSURL *titleURLLAEn;
    NSURL *titleURLSFFr;
    MWKDataStore *dataStore;
    MWKHistoryList *historyList;
}

- (void)setUp {
    [super setUp];

    siteURLEn = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    siteURLFr = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];

    titleURLSFEn = [siteURLEn wmf_URLWithTitle:@"San Francisco"];
    titleURLLAEn = [siteURLEn wmf_URLWithTitle:@"Los Angeles"];
    titleURLSFFr = [siteURLFr wmf_URLWithTitle:@"San Francisco"];

    dataStore = [MWKDataStore temporaryDataStore];
    historyList = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    NSAssert([historyList numberOfItems] == 0, @"History list must be empty before tests begin.");
}

- (void)tearDown {
    [dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testStatePersistsWhenSaved {
    [historyList addPageToHistoryWithURL:titleURLLAEn];
    [historyList addPageToHistoryWithURL:titleURLSFFr];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryList *persistedList = [[MWKHistoryList alloc] initWithDataStore:self->dataStore];

        MWKHistoryEntry *losAngeles2 = [persistedList entryForURL:self->titleURLLAEn];
        MWKHistoryEntry *sanFrancisco2 = [persistedList entryForURL:self->titleURLSFFr];

        XCTAssertEqualObjects(losAngeles2.url.wmf_databaseKey, self->titleURLLAEn.wmf_databaseKey);
        XCTAssertEqualObjects(sanFrancisco2.url.wmf_databaseKey, self->titleURLSFFr.wmf_databaseKey);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testAddingIdenticalObjectUpdatesExistingEntryDate {
    [historyList addPageToHistoryWithURL:titleURLSFEn];

    __block NSDate *originalDateViewed = nil;

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"First save"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry = [self->historyList entryForURL:self->titleURLSFEn];
        originalDateViewed = entry.dateViewed;
        [expectation fulfill];

    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

    [historyList addPageToHistoryWithURL:titleURLSFEn];

    __block XCTestExpectation *secondExpectation = [self expectationWithDescription:@"Second save"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry = [self->historyList entryForURL:self->titleURLSFEn];

        XCTAssertTrue([self->historyList numberOfItems] == 1);
        XCTAssertNotEqualObjects(entry.dateViewed, originalDateViewed);
        [secondExpectation fulfill];

    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testAddingEquivalentObjectUpdatesExistingEntryDate {
    NSURL *title1 = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    [historyList addPageToHistoryWithURL:title1];

    __block NSDate *originalDateViewed = nil;

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"First save"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry = [self->historyList entryForURL:title1];
        originalDateViewed = entry.dateViewed;
        [expectation fulfill];

    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

    NSURL *copyOfTitle1 = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    [historyList addPageToHistoryWithURL:copyOfTitle1];

    __block XCTestExpectation *secondExpectation = [self expectationWithDescription:@"Second save"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry = [self->historyList entryForURL:copyOfTitle1];

        XCTAssertTrue([self->historyList numberOfItems] == 1);
        XCTAssertNotEqualObjects(entry.dateViewed, originalDateViewed);
        [secondExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testAddingTheSameTitleFromDifferentSites {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLSFFr];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{

        MWKHistoryEntry *entry = [self->historyList mostRecentEntry];
        XCTAssertEqualObjects(entry.url.wmf_databaseKey, self->titleURLSFFr.wmf_databaseKey);
        XCTAssertNotEqualObjects(entry.url.wmf_databaseKey, self->titleURLSFEn.wmf_databaseKey);
        [expectation fulfill];

    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testListOrdersByDateDescending {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLLAEn];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry1 = [self->historyList entryForURL:self->titleURLSFEn];
        MWKHistoryEntry *entry2 = [self->historyList entryForURL:self->titleURLLAEn];
        XCTAssertTrue([[entry2.dateViewed laterDate:entry1.dateViewed] isEqualToDate:entry2.dateViewed],
                      @"Test assumes new entries are created w/ the current date.");
        XCTAssertEqual([self->historyList mostRecentEntry], entry2);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testListOrderAfterAddingSameEntry {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLLAEn];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [dataStore notifyWhenWriteTransactionsComplete:^{
        MWKHistoryEntry *entry1 = [self->historyList entryForURL:self->titleURLSFEn];
        MWKHistoryEntry *entry2 = [self->historyList entryForURL:self->titleURLLAEn];
        XCTAssertEqual([self->historyList mostRecentEntry], entry2);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

    __block XCTestExpectation *secondExpectation = [self expectationWithDescription:@"Should resolve"];
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [dataStore notifyWhenWriteTransactionsComplete:^{
        XCTAssertEqual([self->historyList mostRecentEntry].url.wmf_databaseKey, self->titleURLSFEn.wmf_databaseKey);
        [secondExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
