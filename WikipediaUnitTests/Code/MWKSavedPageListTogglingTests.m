#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

@interface MWKSavedPageListTogglingTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList *list;
@property (nonatomic, strong) MWKDataStore *dataStore;

@end

@implementation MWKSavedPageListTogglingTests

- (void)setUp {
    self.dataStore = [MWKDataStore temporaryDataStore];
    self.list = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];
}

#pragma mark - Manual Saving

- (void)testAddedTitlesArePrepended {
    NSURL *second = [NSURL wmf_randomArticleURL];
    [self.list addSavedPageWithURL:[NSURL wmf_randomArticleURL]];
    [self.list addSavedPageWithURL:second];

    WMFArticle *e2 = [self.list entryForURL:second];
    XCTAssertTrue([self.list numberOfItems] == 2);
    XCTAssertEqualObjects(self.list.mostRecentEntry, e2);
}

- (void)testAddingExistingSavedPageIsIgnored {
    NSURL *url = [NSURL wmf_randomArticleURL];
    [self.list addSavedPageWithURL:url];
    [self.list addSavedPageWithURL:url];

    WMFArticle *entry = [self.list entryForURL:url];
    XCTAssertTrue([self.list numberOfItems] == 1);
    XCTAssertEqualObjects(self.list.mostRecentEntry.key, entry.key);
}

#pragma mark - Toggling

- (void)testTogglingSavedPageReturnsNoAndRemovesFromList {
    NSURL *url = [NSURL wmf_randomArticleURL];
    [self.list addSavedPageWithURL:url];
    WMFArticle *savedEntry = [self.list entryForURL:url];
    [self.list toggleSavedPageForURL:savedEntry.URL];
    XCTAssertFalse([self.list isSaved:savedEntry.URL]);
    XCTAssertNil([self.list entryForURL:savedEntry.URL]);
}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    NSURL *unsavedURL = [NSURL wmf_randomArticleURL];
    [self.list toggleSavedPageForURL:unsavedURL];

    XCTAssertTrue([self.list isSaved:unsavedURL]);
    XCTAssertEqualObjects([self.list entryForURL:unsavedURL].key, unsavedURL.wmf_databaseKey);
}

- (void)testTogglePageWithEmptyTitleReturnsNilWithError {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@""];
    @try {
        [self.list toggleSavedPageForURL:url];
    } @catch (NSException *exception) {
        XCTAssertTrue(exception != nil);
    } @finally {
    }
    XCTAssertFalse([self.list isSaved:url]);
}

@end
