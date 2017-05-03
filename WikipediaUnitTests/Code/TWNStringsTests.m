#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface TWNStringsTests : XCTestCase

@property (strong, nonatomic) NSArray *lprojFiles;
@property (strong, nonatomic) NSString *bundleRoot;
@property (strong, nonatomic) NSArray *infoPlistFilePaths;
@property (strong, nonatomic) NSString *twnLocalizationsDirectory;
@property (strong, nonatomic) NSString *iOSLocalizationsDirectory;

@end

@implementation TWNStringsTests

- (void)setUp {
    [super setUp];
    self.twnLocalizationsDirectory = [SOURCE_ROOT_DIR stringByAppendingPathComponent:@"Wikipedia/Localizations"];
    self.iOSLocalizationsDirectory = [SOURCE_ROOT_DIR stringByAppendingPathComponent:@"Wikipedia/iOS Native Localizations"];
    self.bundleRoot = [[NSBundle mainBundle] bundlePath];
    self.lprojFiles = [self bundledLprogFiles];
    self.infoPlistFilePaths = [self.lprojFiles wmf_map:^NSString *(NSString *lprojFileName) {
        return [[self.twnLocalizationsDirectory stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"InfoPlist.strings"];
    }];
}

- (NSArray *)bundledLprogFiles {
    return [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.bundleRoot error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]] valueForKey:@"lowercaseString"];
}

- (NSArray *)allLprogFiles {
    return [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.twnLocalizationsDirectory error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]] valueForKey:@"lowercaseString"];
}

- (NSDictionary *)getPluralizableStringsDictFromLprogAtPath:(NSString *)lprojPath {
    NSString *stringsFilePath = [lprojPath stringByAppendingPathComponent:@"Localizable.stringsdict"];
    return [self getDictFromPListAtPath:stringsFilePath];
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

- (void)testIncomingTranslationStringForReversedSubstitutionShortcuts {
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

- (void)testIncomingTranslationStringForPercentNumber {
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

- (void)testIncomingTranslationStringForPercentS {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(containsSubstring(@"%s")));
        }
    }
}

- (void)testIncomingTranslationStringForHTML {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            assertThat(localizedString, isNot(stringContainsInOrder(@"<", @">", nil)));
            assertThat(localizedString, isNot(containsSubstring(@"&nbsp")));
        }
    }
}

- (void)testIncomingTranslationStringForBracketSubstitutions {
    for (NSString *lprojFileName in self.lprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            NSDictionary *pluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in stringsDict) {
                NSString *localizedString = stringsDict[key];
                if ([localizedString containsString:@"{{"]) {
                    if ([localizedString containsString:@"{{PLURAL:$"]) {
                        XCTAssertNotNil([pluralizableStringsDict objectForKey:key], @"Localizable string with PLURAL: needs an entry in the corresponding stringsdict file");
                    } else {
                        XCTAssertTrue(false, @"Unsupported {{ }} in localization");
                    }
                }
            }
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
                [[self.twnLocalizationsDirectory stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"Localizable.strings"];
            return [[NSFileManager defaultManager] fileExistsAtPath:localizableStringsFilePath isDirectory:&isDirectory];
        }];
}

- (void)testAllTranslatedLanguagesWereAddedToProjectLocalizations {
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

- (void)testEachLprojContainsAnInfoPlistStringsFile {
    for (NSString *path in [self infoPlistFilePaths]) {
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
            XCTAssert(NO, @"Required file not found: %@", path);
        }
    }
}

- (void)testEachInfoPlistStringsFileContainsCFBundleDisplayNameKey {
    for (NSString *path in [self infoPlistFilePaths]) {
        if (![[[self getDictFromPListAtPath:path] allKeys] containsObject:@"CFBundleDisplayName"]) {
            XCTAssert(NO, @"Required CFBundleDisplayName key not found in: %@", path);
        }
    }
}

- (void)testKeysForUnderscores {
    for (NSString *lprojFileName in self.lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            // Keys use dash "-" separators.
            assertThat(key, isNot(containsSubstring(@"_")));
        }
    }
}

- (void)testMismatchedSubstitutions {

    NSString *qqqBundlePath = [self.twnLocalizationsDirectory stringByAppendingPathComponent:@"qqq.lproj"];
    NSDictionary *qqqStringsDict = [self getTranslationStringsDictFromLprogAtPath:qqqBundlePath];

    NSString *enBundlePath = [self.twnLocalizationsDirectory stringByAppendingPathComponent:@"en.lproj"];
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
