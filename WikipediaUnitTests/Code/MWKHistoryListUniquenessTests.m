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

    MWKHistoryList *persistedList = [[MWKHistoryList alloc] initWithDataStore:dataStore];

    WMFArticle *losAngeles2 = [persistedList entryForURL:self->titleURLLAEn];
    WMFArticle *sanFrancisco2 = [persistedList entryForURL:self->titleURLSFFr];

    XCTAssertEqualObjects(losAngeles2.key, self->titleURLLAEn.wmf_databaseKey);
    XCTAssertEqualObjects(sanFrancisco2.key, self->titleURLSFFr.wmf_databaseKey);
}

- (void)testAddingIdenticalObjectUpdatesExistingEntryDate {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    WMFArticle *originalArticle = [self->historyList entryForURL:self->titleURLSFEn];
    NSDate *originalDateViewed = originalArticle.viewedDate;
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    WMFArticle *article = [self->historyList entryForURL:self->titleURLSFEn];
    XCTAssertTrue([self->historyList numberOfItems] == 1);
    XCTAssertNotEqualObjects(article.viewedDate, originalDateViewed);
}

- (void)testAddingEquivalentObjectUpdatesExistingEntryDate {
    NSURL *title1 = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    [historyList addPageToHistoryWithURL:title1];

    WMFArticle *originalArticle = [self->historyList entryForURL:title1];
    NSDate *originalDateViewed = originalArticle.viewedDate;

    NSURL *copyOfTitle1 = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    [historyList addPageToHistoryWithURL:copyOfTitle1];

    WMFArticle *article = [self->historyList entryForURL:copyOfTitle1];

    XCTAssertTrue([self->historyList numberOfItems] == 1);
    XCTAssertNotEqualObjects(article.viewedDate, originalDateViewed);
}

- (void)testAddingTheSameTitleFromDifferentSites {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLSFFr];

    WMFArticle *entry = [self->historyList mostRecentEntry];
    XCTAssertEqualObjects(entry.key, self->titleURLSFFr.wmf_databaseKey);
    XCTAssertNotEqualObjects(entry.key, self->titleURLSFEn.wmf_databaseKey);
}

- (void)testListOrdersByDateDescending {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLLAEn];

    WMFArticle *entry1 = [self->historyList entryForURL:self->titleURLSFEn];
    WMFArticle *entry2 = [self->historyList entryForURL:self->titleURLLAEn];
    XCTAssertTrue([[entry2.viewedDate laterDate:entry1.viewedDate] isEqualToDate:entry2.viewedDate],
                  @"Test assumes new entries are created w/ the current date.");
    XCTAssertEqualObjects([self->historyList mostRecentEntry], entry2);
}

- (void)testListOrderAfterAddingSameEntry {
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    [historyList addPageToHistoryWithURL:titleURLLAEn];

    WMFArticle *entry2 = [self->historyList entryForURL:self->titleURLLAEn];
    XCTAssertEqualObjects([self->historyList mostRecentEntry], entry2);

    [historyList addPageToHistoryWithURL:titleURLSFEn];

    NSString *mostRecentKey = [self->historyList mostRecentEntry].key;
    XCTAssertEqualObjects(mostRecentKey, self->titleURLSFEn.wmf_databaseKey);
}

@end
