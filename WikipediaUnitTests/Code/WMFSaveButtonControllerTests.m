#import <XCTest/XCTest.h>

#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKSavedPageList.h"
#import "WMFSaveButtonController.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSaveButtonControllerTests : XCTestCase
@property(nonatomic, strong) NSURL* siteEn;
@property(nonatomic, strong) NSURL* siteFr;
@property(nonatomic, strong) NSURL* titleSFEn;
@property(nonatomic, strong) NSURL* titleSFFr;
@property(nonatomic, strong) MWKDataStore* dataStore;
@property(nonatomic, strong) MWKSavedPageList* savedPagesList;
@property(nonatomic, strong) WMFSaveButtonController* saveButtonController;
@property(nonatomic, strong) UIButton* button;
@end

@implementation WMFSaveButtonControllerTests

- (void)setUp {
    [super setUp];

    self.dataStore = [MWKDataStore temporaryDataStore];

    self.siteEn = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    self.siteFr = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];

    self.titleSFEn = [self.siteEn wmf_URLWithTitle:@"San Francisco"];
    self.titleSFFr = [self.siteFr wmf_URLWithTitle:@"San Francisco"];

    self.dataStore      = [MWKDataStore temporaryDataStore];
    self.savedPagesList = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];

    self.button               = [[UIButton alloc] init];
    self.saveButtonController = [[WMFSaveButtonController alloc] initWithControl:self.button
                                                                   savedPageList:self.savedPagesList
                                                                           url:nil];

    assertThat(@([self.savedPagesList countOfEntries]), is(equalToInt(0)));
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
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
}

- (void)testShouldUpdateToUnsavedStateWhenTitleIsNullified {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
    self.saveButtonController.url = nil;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testShouldUpdateSavedStateWhenTitleIsRemovedFromListByAnotherObject {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
    [self.savedPagesList removeEntryWithListIndex:self.titleSFEn];
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testShouldUpdateSavedStateWhenTitleIsAddedToListByAnotherObject {
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
}

- (void)testShouldUpdateButtonStateWhenSet {
    self.saveButtonController.url = self.titleSFEn;
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    self.saveButtonController.control = [UIButton new];
    assertThat(@(self.saveButtonController.control.state), is(equalToInt(UIControlStateSelected)));
}

- (void)testToggleFromSavedToUnsaved {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
}

- (void)testToggleFromUnSavedTosaved {
    self.saveButtonController.url = self.titleSFEn;
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
}

- (void)testNoChangeForTitleWhenOtherTitleToggled {
    [self.savedPagesList addSavedPageWithURL:self.titleSFEn];
    [self.savedPagesList addSavedPageWithURL:self.titleSFFr];
    self.saveButtonController.url = self.titleSFEn;
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
    assertThat(@([self.savedPagesList isSaved:self.titleSFFr]), is(@(YES)));
}

@end
