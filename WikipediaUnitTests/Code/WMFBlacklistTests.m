
#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "WMFRelatedSectionBlackList.h"
#import "MWKTitle.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface WMFRelatedSectionBlackList (WMFTesting)

@end


@interface WMFBlacklistTests : WMFAsyncTestCase

@property (nonatomic, strong) MWKDataStore* dataStore;

@end

@implementation WMFBlacklistTests

- (void)setUp {
    self.dataStore = [MWKDataStore temporaryDataStore];
    [super setUp];
}

- (void)tearDown {
    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];
    [bl removeAllEntries];
    self.dataStore = nil;
    [super tearDown];
}

- (void)testPersistsToDisk {
    PushExpectation();
    NSURL* url                     = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"some-title"];
    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];
    [bl addBlackListArticleURL:url];
    bl = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];

    MWKHistoryEntry* first = [bl mostRecentEntry];

    XCTAssertTrue([url isEqual:first.url],
                  @"Title persisted should be equal to the title loaded from disk");
}

@end
