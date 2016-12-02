#import "WMFAsyncTestCase.h"

#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKSavedPageList.h"
#import "WMFSaveButtonController.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSaveButtonControllerTests : XCTestCase
@property (nonatomic, strong) NSURL *siteEn;
@property (nonatomic, strong) NSURL *siteFr;
@property (nonatomic, strong) NSURL *titleSFEn;
@property (nonatomic, strong) NSURL *titleSFFr;
@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) MWKSavedPageList *savedPagesList;
@property (nonatomic, strong) WMFSaveButtonController *saveButtonController;
@property (nonatomic, strong) UIButton *button;
@end

@implementation WMFSaveButtonControllerTests

- (void)setUp {
    [super setUp];

    self.dataStore = [MWKDataStore temporaryDataStore];

    self.siteEn = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    self.siteFr = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];

    self.titleSFEn = [self.siteEn wmf_URLWithTitle:@"San Francisco"];
    self.titleSFFr = [self.siteFr wmf_URLWithTitle:@"San Francisco"];

    self.dataStore = [MWKDataStore temporaryDataStore];
    self.savedPagesList = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];

    self.button = [[UIButton alloc] init];
    self.saveButtonController = [[WMFSaveButtonController alloc] initWithControl:self.button
                                                                   savedPageList:self.savedPagesList
                                                                             url:nil];

    assertThat(@([self.savedPagesList numberOfItems]), is(equalToInt(0)));
}

- (void)tearDown {
    [self.dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testButtonStateForEmptySavedPagesListAndNilTitle {
    self.saveButtonController.url = nil;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testButtonStateForEmptySavedPagesListAndUnsavedTitle {
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testButtonStateForNonEmptySavedPagesListAndUnsavedTitle {
    [self.savedPagesList addSavedPageWithURL:self.titleSFFr];
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testShouldUpdateToSavedStateWhenSetWithSavedTitle {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.saveButtonController.url = self.titleSFEn;
        assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
        [expectation fulfill];
    });


    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testShouldUpdateToUnsavedStateWhenTitleIsNullified {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.saveButtonController.url = self.titleSFEn;
        assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
        self.saveButtonController.url = nil;
        assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testShouldUpdateSavedStateWhenTitleIsRemovedFromListByAnotherObject {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.saveButtonController.url = self.titleSFEn;
        assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
        [self.savedPagesList removeEntryWithURL:self.titleSFEn];

        dispatch_async(dispatch_get_main_queue(), ^{
            assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testShouldUpdateSavedStateWhenTitleIsAddedToListByAnotherObject {
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.savedPagesList addSavedPageWithURL:self.titleSFEn];

        dispatch_async(dispatch_get_main_queue(), ^{
            assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
            assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testShouldUpdateButtonStateWhenSet {
    self.saveButtonController.url = self.titleSFEn;
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.saveButtonController.control = [UIButton new];
        assertThat(@(self.saveButtonController.control.state), is(equalToInt(UIControlStateSelected)));
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testToggleFromSavedToUnsaved {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    self.saveButtonController.url = self.titleSFEn;

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
        [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];

        dispatch_async(dispatch_get_main_queue(), ^{
            assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testToggleFromUnSavedTosaved {
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testNoChangeForTitleWhenOtherTitleToggled {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    [self.savedPagesList addSavedPageWithURL:self.titleSFFr];
    self.saveButtonController.url = self.titleSFEn;

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
        dispatch_async(dispatch_get_main_queue(), ^{
            assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
            assertThat(@([self.savedPagesList isSaved:self.titleSFFr]), is(@(YES)));
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
