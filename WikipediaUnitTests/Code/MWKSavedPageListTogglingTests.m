

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry+Random.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListTogglingTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList* list;
@end

@implementation MWKSavedPageListTogglingTests

- (void)setUp {
    self.list = [[MWKSavedPageList alloc] init];
}

#pragma mark - Manual Saving

- (void)testAddedTitlesArePrepended {
    MWKSavedPageEntry* e1 = [MWKSavedPageEntry random];
    MWKSavedPageEntry* e2 = [MWKSavedPageEntry random];
    [self.list addEntry:e1];
    [self.list addEntry:e2];
    assertThat(self.list.entries, is(@[e2, e1]));
    assertThat(self.list.mostRecentEntry, is(e2));
}

- (void)testAddingExistingSavedPageIsIgnored {
    MWKSavedPageEntry* entry = [MWKSavedPageEntry random];
    [self.list addEntry:entry];
    [self.list addEntry:[[MWKSavedPageEntry alloc] initWithURL:entry.url]];
    assertThat(self.list.entries, is(@[entry]));
}

#pragma mark - Toggling

- (void)testTogglingSavedPageReturnsNoAndRemovesFromList {
    MWKSavedPageEntry* savedEntry = [MWKSavedPageEntry random];
    [self.list addEntry:savedEntry];
    [self.list toggleSavedPageForURL:savedEntry.url];
    XCTAssertFalse([self.list isSaved:savedEntry.url]);
    XCTAssertNil([self.list entryForListIndex:savedEntry.url]);
}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    MWKSavedPageEntry* unsavedEntry = [MWKSavedPageEntry random];
    [self.list toggleSavedPageForURL:unsavedEntry.url];
    XCTAssertTrue([self.list isSaved:unsavedEntry.url]);
    XCTAssertEqualObjects([self.list entryForListIndex:unsavedEntry.url], unsavedEntry);
}

- (void)testTogglePageWithEmptyTitleReturnsNilWithError {
    NSURL* url = [[NSURL wmf_URLWithLanguage:@"en"] wmf_URLWithTitle:@""];
    [self.list toggleSavedPageForURL:url];
    XCTAssertFalse([self.list isSaved:url]);
}

@end
