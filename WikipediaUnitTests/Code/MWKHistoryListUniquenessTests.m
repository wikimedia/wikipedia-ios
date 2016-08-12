
#import "MWKTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "XCTestCase+PromiseKit.h"
#import "MWKList+Subclass.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListUniquenessTests : MWKTestCase

@end

@implementation MWKHistoryListUniquenessTests {
    NSURL* siteURLEn;
    NSURL* siteURLFr;
    NSURL* titleURLSFEn;
    NSURL* titleURLLAEn;
    NSURL* titleURLSFFr;
    MWKDataStore* dataStore;
    MWKHistoryList* historyList;
}

- (void)setUp {
    [super setUp];

    siteURLEn = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    siteURLFr = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];

    titleURLSFEn = [siteURLEn wmf_URLWithTitle:@"San Francisco"];
    titleURLLAEn = [siteURLEn wmf_URLWithTitle:@"Los Angeles"];
    titleURLSFFr = [siteURLFr wmf_URLWithTitle:@"San Francisco"];

    dataStore   = [MWKDataStore temporaryDataStore];
    historyList = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    NSAssert([historyList numberOfItems] == 0, @"History list must be empty before tests begin.");
}

- (void)tearDown {
    [dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testStatePersistsWhenSaved {
    
    MWKHistoryEntry* losAngeles = [historyList addPageToHistoryWithURL:titleURLLAEn];
    MWKHistoryEntry* sanFrancisco =  [historyList addPageToHistoryWithURL:titleURLSFFr];
    
    MWKHistoryList* persistedList = [[MWKHistoryList alloc] initWithDataStore:self->dataStore];
    
    MWKHistoryEntry* losAngeles2 = [persistedList entryForURL:titleURLLAEn];
    MWKHistoryEntry* sanFrancisco2 =  [persistedList entryForURL:titleURLSFFr];

    assertThat(losAngeles2, is(losAngeles));
    assertThat(sanFrancisco2, is(sanFrancisco));
}

- (void)testAddingIdenticalObjectUpdatesExistingEntryDate {
    MWKHistoryEntry* entry = [historyList addPageToHistoryWithURL:titleURLSFEn];
    
    MWKHistoryEntry* entry2 = [historyList addPageToHistoryWithURL:titleURLSFEn];

    MWKHistoryEntry* entry3 = [historyList entryForURL:titleURLSFEn];

    XCTAssertTrue([historyList numberOfItems] == 1);
    assertThat(entry3, is(entry2));
    XCTAssertTrue(![entry3 isEqual:entry]);
}

- (void)testAddingEquivalentObjectUpdatesExistingEntryDate {
    NSURL* title1              = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    MWKHistoryEntry* entry1       = [historyList addPageToHistoryWithURL:title1];

    NSURL* copyOfTitle1        = [titleURLSFEn wmf_URLWithTitle:@"This is a title"];
    MWKHistoryEntry* copyOfEntry1 = [historyList addPageToHistoryWithURL:copyOfTitle1];
    
    MWKHistoryEntry* copyOfEntry2 = [historyList entryForURL:titleURLSFEn];

    assertThat(copyOfEntry2, is(copyOfEntry1));
    XCTAssertTrue(![copyOfEntry2 isEqual:entry1]);
}

- (void)testAddingTheSameTitleFromDifferentSites {
    MWKHistoryEntry* en = [historyList addPageToHistoryWithURL:titleURLSFEn];
    MWKHistoryEntry* fr = [historyList addPageToHistoryWithURL:titleURLSFFr];
    
    MWKHistoryEntry* entry = [historyList mostRecentEntry];
    assertThat(fr, is(entry));
    XCTAssertTrue(![en isEqual:entry]);
}

- (void)testListOrdersByDateDescending {
    MWKHistoryEntry* entry1 = [historyList addPageToHistoryWithURL:titleURLSFEn];
    MWKHistoryEntry* entry2 = [historyList addPageToHistoryWithURL:titleURLLAEn];
    NSAssert([[entry2.dateViewed laterDate:entry1.dateViewed] isEqualToDate:entry2.dateViewed],
             @"Test assumes new entries are created w/ the current date.");
    assertThat([historyList mostRecentEntry], is(entry2));
}

- (void)testListOrderAfterAddingSameEntry {
    MWKHistoryEntry* entry1 = [historyList addPageToHistoryWithURL:titleURLSFEn];
    MWKHistoryEntry* entry2 = [historyList addPageToHistoryWithURL:titleURLLAEn];
    assertThat([historyList mostRecentEntry], is(entry2));
    [historyList addPageToHistoryWithURL:titleURLSFEn];
    assertThat([historyList mostRecentEntry].url, is(entry1.url));
}

@end
