//  Created by Monte Hurd on 8/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <XCTest/XCTest.h>

#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"
#import "WMFSaveButtonController.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSaveButtonControllerTests : XCTestCase
@property(nonatomic, strong) MWKSite* siteEn;
@property(nonatomic, strong) MWKSite* siteFr;
@property(nonatomic, strong) MWKTitle* titleSFEn;
@property(nonatomic, strong) MWKTitle* titleSFFr;
@property(nonatomic, strong) MWKDataStore* dataStore;
@property(nonatomic, strong) MWKSavedPageList* savedPagesList;
@property(nonatomic, strong) WMFSaveButtonController* saveButtonController;
@property(nonatomic, strong) UIButton* button;
@end

@implementation WMFSaveButtonControllerTests

- (void)setUp {
    [super setUp];

    self.dataStore = [MWKDataStore temporaryDataStore];

    self.siteEn = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    self.siteFr = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];

    self.titleSFEn = [self.siteEn titleWithString:@"San Francisco"];
    self.titleSFFr = [self.siteFr titleWithString:@"San Francisco"];

    self.dataStore      = [MWKDataStore temporaryDataStore];
    self.savedPagesList = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];

    self.button               = [[UIButton alloc] init];
    self.saveButtonController = [[WMFSaveButtonController alloc] initWithButton:self.button savedPageList:self.savedPagesList title:nil];

    assertThat(@([self.savedPagesList countOfEntries]), is(equalToInt(0)));
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testButtonStateForEmptySavedPagesListAndNilTitle {
    [self.savedPagesList removeAllSavedPages];
    self.saveButtonController.title = nil;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testButtonStateForEmptySavedPagesListAndUnsavedTitle {
    [self.savedPagesList removeAllSavedPages];
    self.saveButtonController.title = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testButtonStateForNonEmptySavedPagesListAndUnsavedTitle {
    [self.savedPagesList removeAllSavedPages];
    [self.savedPagesList addSavedPageWithTitle:self.titleSFFr];
    self.saveButtonController.title = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateNormal)));
}

- (void)testButtonStateForNonEmptySavedPagesListAndSavedTitle {
    [self.savedPagesList removeAllSavedPages];
    [self.savedPagesList addSavedPageWithTitle:self.titleSFEn];
    self.saveButtonController.title = self.titleSFEn;
    assertThat(@(self.button.state), is(equalToInt(UIControlStateSelected)));
}

- (void)testToggleFromSavedToUnsaved {
    [self.savedPagesList removeAllSavedPages];
    [self.savedPagesList addSavedPageWithTitle:self.titleSFEn];
    self.saveButtonController.title = self.titleSFEn;
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
}

- (void)testToggleFromUnSavedTosaved {
    [self.savedPagesList removeAllSavedPages];
    self.saveButtonController.title = self.titleSFEn;
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(YES)));
}

- (void)testNoChangeForTitleWhenOtherTitleToggled {
    [self.savedPagesList removeAllSavedPages];
    [self.savedPagesList addSavedPageWithTitle:self.titleSFEn];
    [self.savedPagesList addSavedPageWithTitle:self.titleSFFr];
    self.saveButtonController.title = self.titleSFEn;
    [self.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    assertThat(@([self.savedPagesList isSaved:self.titleSFEn]), is(@(NO)));
    assertThat(@([self.savedPagesList isSaved:self.titleSFFr]), is(@(YES)));
}

@end
