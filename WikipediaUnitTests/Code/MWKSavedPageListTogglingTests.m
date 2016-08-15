

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"
#import "NSDate+Utilities.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListTogglingTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList* list;
@property (nonatomic, strong) MWKDataStore* dataStore;

@end

@implementation MWKSavedPageListTogglingTests

- (void)setUp {
    self.dataStore = [MWKDataStore temporaryDataStore];
    self.list      = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];
}

#pragma mark - Manual Saving

- (void)testAddedTitlesArePrepended {
    [self.list addSavedPageWithURL:[NSURL wmf_randomArticleURL]];
    MWKHistoryEntry* e2 = [self.list addSavedPageWithURL:[NSURL wmf_randomArticleURL]];
    
    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        XCTAssertTrue([self.list numberOfItems] == 2);
        assertThat(self.list.mostRecentEntry, is(e2));
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

}

- (void)testAddingExistingSavedPageIsIgnored {
    MWKHistoryEntry* entry = [self.list addSavedPageWithURL:[NSURL wmf_randomArticleURL]];
    [self.list addSavedPageWithURL:entry.url];
    
    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        XCTAssertTrue([self.list numberOfItems] == 1);
        assertThat(self.list.mostRecentEntry.url, is(entry.url));
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

}

#pragma mark - Toggling

- (void)testTogglingSavedPageReturnsNoAndRemovesFromList {
    MWKHistoryEntry* savedEntry = [self.list addSavedPageWithURL:[NSURL wmf_randomArticleURL]];
    
    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];

    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        [self.list toggleSavedPageForURL:savedEntry.url];
        dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
            XCTAssertFalse([self.list isSaved:savedEntry.url]);
            XCTAssertNil([self.list entryForURL:savedEntry.url]);
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    MWKHistoryEntry* unsavedEntry = [MWKHistoryEntry random];
    [self.list toggleSavedPageForURL:unsavedEntry.url];
    
    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        XCTAssertTrue([self.list isSaved:unsavedEntry.url]);
        XCTAssertEqualObjects([self.list entryForURL:unsavedEntry.url].url, unsavedEntry.url);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

}

- (void)testTogglePageWithEmptyTitleReturnsNilWithError {
    NSURL* url = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@""];
    [self.list toggleSavedPageForURL:url];
    
    __block XCTestExpectation* expectation = [self expectationWithDescription:@"Should resolve"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        XCTAssertFalse([self.list isSaved:url]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];

}

@end
