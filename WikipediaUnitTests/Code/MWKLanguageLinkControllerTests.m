#import <XCTest/XCTest.h>
#import "MWKLanguageLinkController_Private.h"
#import "MWKLanguageLink.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "NSString+WMFExtras.h"
#import "NSUserDefaults+WMFReset.h"

@interface MWKLanguageLinkControllerTests : XCTestCase
@property (strong, nonatomic) MWKLanguageLinkController *controller;
@property (strong, nonatomic) MWKLanguageFilter *filter;

@end

@implementation MWKLanguageLinkControllerTests

- (void)setUpWithCompletionHandler:(void (^)(NSError * _Nullable))completion {
    
    [[NSUserDefaults standardUserDefaults] wmf_resetToDefaultValues];

    NSAssert([[NSLocale preferredLanguages] containsObject:@"en-US"] || [[NSLocale preferredLanguages] containsObject:@"en"],
             @"For simplicity these tests assume the simulator has 'English' has one of its preferred languages."
              " Instead, these were the preferred languages: %@",
             [NSLocale preferredLanguages]);

    
    [MWKDataStore createTemporaryDataStoreWithCompletion:^(MWKDataStore * _Nonnull dataStore) {
        self.controller = dataStore.languageLinkController;
        self.filter = [[MWKLanguageFilter alloc] initWithLanguageDataSource:self.controller];
        [self.controller resetPreferredLanguages];
        completion(nil);
    }];
}

- (void)testReadPreviouslySelectedLanguagesReturnsEmpty {
    XCTAssertEqual([[self.controller readSavedPreferredLanguageCodes] count], 0);
}

- (void)testDefaultsToDevicePreferredLanguages {
    /*
       since we've asserted above that "en" or "en-US" is one of the OS preferred languages, we can assert that our
       controller contains a language link for "en"
     */
    XCTAssert([[self preferredLanguageCodes] containsObject:@"en"]);
    [self verifyAllLanguageArrayProperties];
}

- (void)testSaveSelectedLanguageUpdatesTheControllersFilteredPreferredLanguages {
    //    NSAssert(![[self preferredLanguageCodes] containsObject:@"test"],
    //             @"'test' shouldn't be a default member of preferred languages!");

    MWKLanguageLink *link = [[MWKLanguageLink alloc] initWithLanguageCode:@"test" pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:@"test" altISOCode:nil];
    [self.controller appendPreferredLanguage:link];

    XCTAssert([[self preferredLanguageCodes] containsObject:@"test"]);
    [self verifyAllLanguageArrayProperties];
}

- (void)testUniqueAppendToPreferredLanguages {
    MWKLanguageLink *link = [[MWKLanguageLink alloc] initWithLanguageCode:@"test" pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:@"test" altISOCode:nil];
    [self.controller appendPreferredLanguage:link];
    NSArray *firstAppend = [self.controller.preferredLanguages copy];

    [self.controller appendPreferredLanguage:link];
    NSArray *secondAppend = [self.controller.preferredLanguages copy];

    XCTAssertEqualObjects(firstAppend, secondAppend);

    [self verifyAllLanguageArrayProperties];
}

- (void)testLanguagesPropertiesAreNonnull {
    XCTAssertTrue(self.controller.allLanguages.count > 0);
    XCTAssertTrue(self.controller.otherLanguages.count > 0);
    XCTAssertTrue(self.controller.preferredLanguages.count > 0);
    [self verifyAllLanguageArrayProperties];
}

- (void)testBasicFiltering {
    self.filter.languageFilter = @"en";

    XCTAssert([self.filter.filteredLanguages wmf_reject:^BOOL(MWKLanguageLink *langLink) {
                  return [langLink.name wmf_caseInsensitiveContainsString:@"en"] || [langLink.localizedName wmf_caseInsensitiveContainsString:@"en"];
              }].count == 0,
              @"All filtered languages have a name or localized name containing filter ignoring case");
    [self verifyAllLanguageArrayProperties];
}

- (void)testEmptyAfterFiltering {
    self.filter.languageFilter = @"$";
    XCTAssert(self.filter.filteredLanguages.count == 0);
}

- (void)testContentLanguageCodeProperty {
    NSString *languageCode = @"zh";
    NSString *languageVariantCode = @"zh-hans";

    // If languageVariantCode is non-nil and non-empty string, contentLanguageCode returns languageVariantCode
    MWKLanguageLink *link = [[MWKLanguageLink alloc] initWithLanguageCode:languageCode pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:languageVariantCode altISOCode:nil];
    XCTAssertEqualObjects(link.contentLanguageCode, languageVariantCode);

    // If languageVariantCode is nil, contentLanguageCode returns languageCode
    link = [[MWKLanguageLink alloc] initWithLanguageCode:languageCode pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:nil altISOCode:nil];
    XCTAssertEqualObjects(link.contentLanguageCode, languageCode);

    // If languageVariantCode is an empty string, contentLanguageCode returns languageCode
    link = [[MWKLanguageLink alloc] initWithLanguageCode:languageCode pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:@"" altISOCode:nil];
    XCTAssertEqualObjects(link.contentLanguageCode, languageCode);
}

- (void)testLanguageVariantCodeURLPropagation {
    NSString *languageCode = @"sr";
    NSString *languageVariantCode = @"sr-el";

    // The languageVariantCode property should propagate to the siteURL.
    MWKLanguageLink *link = [[MWKLanguageLink alloc] initWithLanguageCode:languageCode pageTitleText:@"test" name:@"test" localizedName:@"test" languageVariantCode:languageVariantCode altISOCode:nil];
    NSURL *siteURL = link.siteURL;
    XCTAssertEqualObjects(siteURL.wmf_languageVariantCode, languageVariantCode);

    // The languageVariantCode property should propagate to the articleURL.
    link = [[MWKLanguageLink alloc] initWithLanguageCode:languageCode pageTitleText:@"PageTitle" name:@"test" localizedName:@"test" languageVariantCode:languageVariantCode altISOCode:nil];
    NSURL *articleURL = link.articleURL;
    XCTAssertEqualObjects(articleURL.wmf_languageVariantCode, languageVariantCode);
}

/* Note that this test relies on the OS *not* having Uzbek set as a preferred language.
 * Since there is no way to change OS language settings from a test, to check the fallback
 * setting if a language is not found in the app or the OS preferred languages, the tested
 * language cannot be one of the OS preferred langugages.
 *
 * Choosing Uzbek since it is a less frequently used language and because it has the most
 * fallback choices of any variant-aware language except for Chinese.
 */
- (void)testPreferredLanguageVariantForLanguageCode {
    NSInteger foundIndex = [NSLocale.preferredLanguages indexOfObjectPassingTest:^BOOL(NSString * _Nonnull languageCode, NSUInteger idx, BOOL * _Nonnull stop) {
        return [languageCode hasPrefix:@"uz"];
    }];
    if (foundIndex != NSNotFound) {
        XCTFail(@"Test being run with Uzbek included in OS preferred languages: '%@'", NSLocale.preferredLanguages[foundIndex]);
    }
    
    NSString *chineseLanguageVariantCode = @"zh-Hans-MY";
    NSString *uzbekLanguageVariantCode = @"uz-Latn";

    MWKLanguageLink *link = [[MWKLanguageLink alloc] initWithLanguageCode:@"zh" pageTitleText:@"" name:@"Malaysia Simplified" localizedName:@"大马简体" languageVariantCode:chineseLanguageVariantCode altISOCode:nil];
    
    // Add langugage link and reorder to the front, so that regardless of the
    // system langauge settings, this link is the first found variant for this language
    [self.controller appendPreferredLanguage:link];
    [self.controller reorderPreferredLanguage:link toIndex:0];
    
    // Test finding in app preferences
    NSString *chineseResult = [self.controller preferredLanguageVariantCodeForLanguageCode:@"zh"];
    XCTAssertEqualObjects(chineseResult, chineseLanguageVariantCode);

    // Test fallback not in app preferences or OS preferences
    NSString *uzbekResult = [self.controller preferredLanguageVariantCodeForLanguageCode:@"uz"];
    XCTAssertEqualObjects(uzbekResult, uzbekLanguageVariantCode);

    // Test non-variant languages not found in app or OS preferences
    NSString *englishResult = [self.controller preferredLanguageVariantCodeForLanguageCode:@"en"];
    XCTAssertNil(englishResult);

    NSString *frenchResult = [self.controller preferredLanguageVariantCodeForLanguageCode:@"fr"];
    XCTAssertNil(frenchResult);
}

- (void)testLanguageCodeForISOLanguageCode {
    
    // Test the single case where the ISO language code does not match the Wikipedia language code
    NSString *norwegianISOCode = @"nb";
    NSString *norwegianLanguageCode = @"no";

    NSString *norwegianResult = [MWKLanguageLinkController languageCodeForISOLanguageCode:norwegianISOCode];
    XCTAssertEqualObjects(norwegianResult, norwegianLanguageCode);
    
    // Test that other language codes are returned just as passed in
    // Note that the method does not check if the passed in code is a valid language code
    NSArray<NSString *> *identicalLanguageCodes = @[@"de", @"ja", @"en", @"es", @"zh", @"uz"];
    
    for (NSString *currentLanguageCode in identicalLanguageCodes) {
        NSString *result = [MWKLanguageLinkController languageCodeForISOLanguageCode:currentLanguageCode];
        XCTAssertEqualObjects(result, currentLanguageCode);
    }
    
    // Test that if a nil value is passed in, nil is returned
    NSString *expectingNil = [MWKLanguageLinkController languageCodeForISOLanguageCode:nil];
    XCTAssertNil(expectingNil);
}

- (void)testDuplicateLanguageCodeFiltering {
    // This tests that the first item is the one that remains in an ordered set if there are duplicate items.
    // This ensures that the preferred langauge uniquing code will behave as expected.
    NSArray *array = @[@"en", @"no", @"fr", @"no"];
    NSArray *expectedResult = @[@"en", @"no", @"fr"];
    NSArray *uniquedArray = [[NSOrderedSet orderedSetWithArray:array] array];
    XCTAssertEqualObjects(uniquedArray, expectedResult);
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
    NSSet *joinedLanguages = [NSSet setWithArray:
                                        [self.controller.preferredLanguages
                                            arrayByAddingObjectsFromArray:self.controller.otherLanguages]];

    XCTAssert(joinedLanguages.count == self.controller.otherLanguages.count + self.controller.preferredLanguages.count);

    XCTAssertEqualObjects([NSSet setWithArray:self.controller.allLanguages], joinedLanguages);
}

- (NSArray<NSString *> *)preferredLanguageCodes {
    return [self.controller.preferredLanguages valueForKey:WMF_SAFE_KEYPATH(MWKLanguageLink.new, languageCode)];
}

- (NSArray *)allLanguageCodes {
    return [self.controller.allLanguages valueForKey:WMF_SAFE_KEYPATH(MWKLanguageLink.new, languageCode)];
}

@end
