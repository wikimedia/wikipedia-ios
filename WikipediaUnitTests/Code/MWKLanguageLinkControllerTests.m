//
//  MWKLanguageLinkControllerTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKLanguageLinkController_Private.h"
#import "MWKLanguageLink.h"
#import <OCHamcrest/OCHamcrest.h>
#import "NSString+Extras.h"

@interface MWKLanguageLinkControllerTests : XCTestCase
@property (strong, nonatomic) MWKLanguageLinkController* controller;
@end

@implementation MWKLanguageLinkControllerTests

- (void)setUp {
    [super setUp];

    NSAssert([[NSLocale preferredLanguages] containsObject:@"en-US"]
             || [[NSLocale preferredLanguages] containsObject:@"en"],
             @"For simplicity these tests assume the simulator has 'English' has one of its preferred languages."
             " Instead, these were the preferred languages: %@", [NSLocale preferredLanguages]);

    // all tests must start w/ a clean slate
    self.controller = [MWKLanguageLinkController sharedInstance];
    [self.controller resetPreferredLanguages];
}

- (void)testReadPreviouslySelectedLanguagesReturnsEmpty {
    assertThat([self.controller readPreferredLanguageCodesWithoutOSPreferredLanguages], hasCountOf(0));
}

- (void)testDefaultsToDevicePreferredLanguages {
    /*
       since we've asserted above that "en" or "en-US" is one of the OS preferred languages, we can assert that our
       controller contains a language link for "en"
     */
    assertThat([self preferredLanguageCodes], contains(@"en", nil));
    [self verifyAllLanguageArrayProperties];
}

- (void)testSaveSelectedLanguageUpdatesTheControllersFilteredPreferredLanguages {
    NSAssert(![[self preferredLanguageCodes] containsObject:@"test"],
             @"'test' shouldn't be a default member of preferred languages!");

    [self.controller appendPreferredLanguageForCode:@"test"];

    assertThat([self preferredLanguageCodes], hasItem(@"test"));
    [self verifyAllLanguageArrayProperties];
}

- (void)testUniqueAppendToPreferredLanguages {
    [self.controller appendPreferredLanguageForCode:@"test"];
    NSArray* firstAppend = [self.controller.preferredLanguages copy];

    [self.controller appendPreferredLanguageForCode:@"test"];
    NSArray* secondAppend = [self.controller.preferredLanguages copy];

    assertThat(firstAppend, is(equalTo(secondAppend)));

    [self verifyAllLanguageArrayProperties];
}

- (void)testPersistentSaves {
    id firstController = self.controller;
    [firstController saveSelectedLanguageCode:@"test"];
    [self instantiateController];
    NSParameterAssert(firstController != self.controller);
    assertThat(self.controller.filteredPreferredLanguageCodes, hasItem(@"test"));
    [self verifyAllLanguageArrayProperties];
}

- (void)testNoPreferredLanguages {
    // reset langlinks to only those _not_ contained in preferred languages
    // this mimics the case where an article's available languages don't contain any of the preferred languages
    self.controller.languageLinks = [self.controller.languageLinks bk_reject:^BOOL (MWKLanguageLink* langLink) {
        return [self.controller.filteredPreferredLanguages containsObject:langLink];
    }];

    [self verifyAllLanguageArrayProperties];
}

- (void)testLanguagesPropertiesAreNonnull {
    self.controller = [MWKLanguageLinkController new];
    assertThat(self.controller.languageLinks, isEmpty());
    assertThat(self.controller.filteredOtherLanguages, isEmpty());
    assertThat(self.controller.filteredPreferredLanguages, isEmpty());
    [self verifyAllLanguageArrayProperties];
}

- (void)testBasicFiltering {
    self.controller.languageFilter = @"en";
    assertThat([self.controller.filteredLanguages bk_reject:^BOOL (MWKLanguageLink* langLink) {
        return [langLink.name wmf_caseInsensitiveContainsString:@"en"]
        || [langLink.localizedName wmf_caseInsensitiveContainsString:@"en"];
    }], describedAs(@"All filtered languages have a name or localized name containing filter ignoring case",
                    isEmpty(), nil));
    [self verifyAllLanguageArrayProperties];
}

- (void)testEmptyAfterFiltering {
    self.controller.languageFilter = @"$";
    assertThat(self.controller.filteredLanguages, isEmpty());
}

#pragma mark - Utils

- (void)verifyAllLanguageArrayProperties {
    [self verifyPreferredAndOtherSumIsAllLanguages];
    [self verifyPreferredAndOtherAreDisjoint];
}

- (void)verifyPreferredAndOtherAreDisjoint {
    XCTAssertFalse([[NSSet setWithArray:self.controller.preferredLanguages]
                    intersectsSet:
                    [NSSet setWithArray:self.controller.otherLanguages]],
                   @"'preferred' and 'other' languages shouldn't intersect: \n preferred: %@ \nother: %@",
                   self.controller.preferredLanguages, self.controller.otherLanguages);
}

- (void)verifyPreferredAndOtherSumIsAllLanguages {
    NSSet* joinedLanguages = [NSSet setWithArray:
                              [self.controller.preferredLanguages
                               arrayByAddingObjectsFromArray:self.controller.otherLanguages]];

    assertThat(joinedLanguages,
               hasCountOf(self.controller.otherLanguages.count
                          + self.controller.preferredLanguages.count));

    assertThat([NSSet setWithArray:self.controller.allLanguages], is(equalTo(joinedLanguages)));
}

- (NSArray<NSString*>*)preferredLanguageCodes {
    return [self.controller.preferredLanguages valueForKey:WMF_SAFE_KEYPATH(MWKLanguageLink.new, languageCode)];
}

- (NSArray*)allLanguageCodes {
    return [self.controller.allLanguages valueForKey:WMF_SAFE_KEYPATH(MWKLanguageLink.new, languageCode)];
}

@end
