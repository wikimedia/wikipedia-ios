#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface TWNStringsTests : XCTestCase

@property (strong, nonatomic) NSArray *lprojFiles;
@property (strong, nonatomic) NSString *bundleRoot;
@property (strong, nonatomic) NSArray *infoPlistFilePaths;

@end

@implementation TWNStringsTests

- (void)setUp {
    [super setUp];
    self.bundleRoot = [[NSBundle mainBundle] bundlePath];
    self.lprojFiles = [self bundledLprogFiles];
    self.infoPlistFilePaths = [self.lprojFiles wmf_map:^NSString *(NSString *lprojFileName) {
        return [[LOCALIZATIONS_DIR stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"InfoPlist.strings"];
    }];
}

- (NSArray *)bundledLprogFiles {
    return [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.bundleRoot error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]];
}

- (NSArray *)allLprogFiles {
    return [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:LOCALIZATIONS_DIR error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]];
}

- (NSDictionary *)getTranslationStringsDictFromLprogAtPath:(NSString *)lprojPath {
    NSString *stringsFilePath = [lprojPath stringByAppendingPathComponent:@"Localizable.strings"];
    return [self getDictFromPListAtPath:stringsFilePath];
}

- (NSDictionary *)getDictFromPListAtPath:(NSString *)path {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        return [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return nil;
}

- (NSMutableOrderedSet *)dollarSubstitutionsInString:(NSString *)s {
    NSMutableOrderedSet *substitutions = [[NSMutableOrderedSet alloc] initWithCapacity:5];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\$[1-5]" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *matches = [regex matchesInString:s options:0 range:NSMakeRange(0, [s length])];
    for (NSTextCheckingResult *match in matches) {
        [substitutions addObject:[s substringWithRange:match.range]];
    }
    return substitutions;
}

- (void)test_lproj_count {
    assertThat(@(self.lprojFiles.count), is(greaterThan(@(0))));
}

- (void)test_incoming_translation_string_for_reversed_substitution_shortcuts {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(containsSubstring(@"1$")));
            assertThat(localizedString, isNot(containsSubstring(@"2$")));
            assertThat(localizedString, isNot(containsSubstring(@"3$")));
            assertThat(localizedString, isNot(containsSubstring(@"4$")));
            assertThat(localizedString, isNot(containsSubstring(@"5$")));
        }
    }
}

- (void)test_incoming_translation_string_for_percent_number {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(containsSubstring(@"%1")));
            assertThat(localizedString, isNot(containsSubstring(@"%2")));
            assertThat(localizedString, isNot(containsSubstring(@"%3")));
            assertThat(localizedString, isNot(containsSubstring(@"%4")));
            assertThat(localizedString, isNot(containsSubstring(@"%5")));
        }
    }
}

- (void)test_incoming_translation_string_for_percent_s {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(containsSubstring(@"%s")));
        }
    }
}

- (void)test_incoming_translation_string_for_html {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(stringContainsInOrder(@"<", @">", nil)));
            assertThat(localizedString, isNot(containsSubstring(@"&nbsp")));
        }
    }
}

- (NSArray *)unbundledLprojFiles {
    NSMutableArray *files = [[self allLprogFiles] mutableCopy];
    [files removeObjectsInArray:[self bundledLprogFiles]];
    return files;
}

- (NSArray *)unbundledLprojFilesWithTranslations {
    // unbundled lProj's containing "Localizable.strings"
    return
        [self.unbundledLprojFiles wmf_select:^BOOL(NSString *lprojFileName) {
            BOOL isDirectory = NO;
            NSString *localizableStringsFilePath =
                [[LOCALIZATIONS_DIR stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"Localizable.strings"];
            return [[NSFileManager defaultManager] fileExistsAtPath:localizableStringsFilePath isDirectory:&isDirectory];
        }];
}

- (void)test_all_translated_languages_were_added_to_project_localizations {
    NSMutableArray *files = [self.unbundledLprojFilesWithTranslations mutableCopy];
    [files removeObjectsInArray:[self languagesUnsureHowToMapToWikiCodes]];

    // Fails if any lproj languages have translations (in "Localizable.strings") but are
    // not yet bundled in the project.

    // So, if this test fails, the languages listed will need to be added these to the project's localizations.

    XCTAssertEqualObjects(files, @[@"qqq.lproj"]); //qqq.lproj should not be in the app bundle
}

- (NSArray *)languagesUnsureHowToMapToWikiCodes {
    // These have no obvious mappings to the lang options Apple provides...
    // TODO: ^ revisit these
    return @[
        @"azb.lproj",
        @"be-tarask.lproj",
        @"bgn.lproj",
        @"cnh.lproj",
        @"ku-latn.lproj",
        @"mai.lproj",
        @"pt-br.lproj", // for some reason Brazilian Portugese is still showing up as not bundled, but I added it... hmm...
        @"sa.lproj",
        @"sd.lproj",
        @"tl.lproj",
        @"vec.lproj",
        @"xmf.lproj",
        @"ba.lproj",
        @"tcy.lproj", // Tulu is written in Kannada alphabet, but "kn" wiki is already associated with "kn" localization.
        @"jv.lproj"   // No keyboard or iOS localization for Javanese at the moment.
    ];
}

- (void)test_each_lproj_contains_an_InfoPlist_strings_file {
    for (NSString *path in [self infoPlistFilePaths]) {
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
            XCTAssert(NO, @"Required file not found: %@", path);
        }
    }
}

- (void)test_each_InfoPlist_strings_file_contains_CFBundleDisplayName_key {
    for (NSString *path in [self infoPlistFilePaths]) {
        if (![[[self getDictFromPListAtPath:path] allKeys] containsObject:@"CFBundleDisplayName"]) {
            XCTAssert(NO, @"Required CFBundleDisplayName key not found in: %@", path);
        }
    }
}

- (void)test_keys_for_underscores {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            // Keys use dash "-" separators.
            assertThat(key, isNot(containsSubstring(@"_")));
        }
    }
}

- (void)test_mismatched_substitutions {

    NSString *qqqBundlePath = [LOCALIZATIONS_DIR stringByAppendingPathComponent:@"qqq.lproj"];
    NSDictionary *qqqStringsDict = [self getTranslationStringsDictFromLprogAtPath:qqqBundlePath];

    NSString *enBundlePath = [LOCALIZATIONS_DIR stringByAppendingPathComponent:@"en.lproj"];
    NSDictionary *enStringsDict = [self getTranslationStringsDictFromLprogAtPath:enBundlePath];

    for (NSString *key in enStringsDict) {

        NSString *enVal = enStringsDict[key];
        NSOrderedSet *enSubstitutions = [self dollarSubstitutionsInString:enVal];
        NSUInteger enSubstituionCount = [enSubstitutions count];

        NSString *qqqVal = qqqStringsDict[key];
        if (!qqqVal) {
            XCTFail(@"missing description in qqq.lproj for key: %@", key);
        }
        NSOrderedSet *qqqSubstitutions = [self dollarSubstitutionsInString:qqqVal];
        NSUInteger qqqSubstituionCount = [qqqSubstitutions count];

        if (enSubstituionCount != qqqSubstituionCount) {
            XCTFail(@"en.lproj:%@ contains %tu substitution(s), but qqq.lproj:%@ describes %tu substitution(s)", key, enSubstituionCount, key, qqqSubstituionCount);
        }
    }
}

- (void)tearDown {
    [super tearDown];
    self.lprojFiles = nil;
    self.bundleRoot = nil;
    self.infoPlistFilePaths = nil;
}

@end
