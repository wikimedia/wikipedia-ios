#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@import WMF;

@interface TWNStringsTests : XCTestCase

@property (class, strong, nonatomic, readonly) NSArray *bundledLprojFiles;
@property (class, strong, nonatomic, readonly) NSArray *iOSLprojFiles;
@property (class, strong, nonatomic, readonly) NSArray *twnLprojFiles;
@property (class, strong, nonatomic, readonly) NSString *bundleRoot;
@property (class, strong, nonatomic, readonly) NSArray *twnInfoPlistFilePaths;
@property (class, strong, nonatomic, readonly) NSArray *iOSInfoPlistFilePaths;
@property (class, strong, nonatomic, readonly) NSString *twnLocalizationsDirectory;
@property (class, strong, nonatomic, readonly) NSString *iOSLocalizationsDirectory;

@end

@implementation TWNStringsTests

- (void)setUp {
    [super setUp];
}

+ (NSString *)iOSLocalizationsDirectory {
    return [SOURCE_ROOT_DIR stringByAppendingPathComponent:@"Wikipedia/iOS Native Localizations"];
}

+ (NSString *)twnLocalizationsDirectory {
    return [SOURCE_ROOT_DIR stringByAppendingPathComponent:@"Wikipedia/Localizations"];
}

+ (NSString *)bundleRoot {
    return [[NSBundle wmf_localizationBundle] bundlePath];
}

+ (NSString *)appBundleRoot {
    return [[NSBundle mainBundle] bundlePath];
}

+ (NSArray *)bundledLprojFiles {
    static dispatch_once_t onceToken;
    static NSArray *bundledLprojFiles;
    dispatch_once(&onceToken, ^{
        bundledLprojFiles = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:TWNStringsTests.bundleRoot error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]] valueForKey:@"lowercaseString"];
    });
    return bundledLprojFiles;
}

+ (NSArray *)twnInfoPlistFilePaths {
    static dispatch_once_t onceToken;
    static NSArray *twnInfoPlistFilePaths;
    dispatch_once(&onceToken, ^{
        twnInfoPlistFilePaths = [self.twnLprojFiles wmf_map:^NSString *(NSString *lprojFileName) {
            return [[self.twnLocalizationsDirectory stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"InfoPlist.strings"];
        }];
    });
    return twnInfoPlistFilePaths;
}

+ (NSArray *)iOSInfoPlistFilePaths {
    static dispatch_once_t onceToken;
    static NSArray *infoPlistFilePaths;
    dispatch_once(&onceToken, ^{
        infoPlistFilePaths = [self.iOSLprojFiles wmf_map:^NSString *(NSString *lprojFileName) {
            return [[self.iOSLocalizationsDirectory stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"InfoPlist.strings"];
        }];
    });
    return infoPlistFilePaths;
}

+ (NSArray *)twnLprojFiles {
    static dispatch_once_t onceToken;
    static NSArray *twnLprojFiles;
    dispatch_once(&onceToken, ^{
        twnLprojFiles = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.twnLocalizationsDirectory error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]] valueForKey:@"lowercaseString"];
    });
    return twnLprojFiles;
}

+ (NSArray *)iOSLprojFiles {
    static dispatch_once_t onceToken;
    static NSArray *iOSLprojFiles;
    dispatch_once(&onceToken, ^{
        iOSLprojFiles = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.iOSLocalizationsDirectory error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]] valueForKey:@"lowercaseString"];
    });
    return iOSLprojFiles;
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
    NSRegularExpression *regex = [TWNStringsTests twnTokenRegex];
    NSArray *matches = [regex matchesInString:s options:0 range:NSMakeRange(0, [s length])];
    for (NSTextCheckingResult *match in matches) {
        [substitutions addObject:[s substringWithRange:match.range]];
    }
    return substitutions;
}

- (void)testLprojCount {
    XCTAssert(TWNStringsTests.iOSLprojFiles.count > 0);
    XCTAssert(TWNStringsTests.twnLprojFiles.count > 0);
}

+ (NSRegularExpression *)reverseTWNTokenRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *reverseTWNTokenRegex;
    dispatch_once(&onceToken, ^{
        reverseTWNTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"(:?[^%%])(:?[0-9]+)(?:[$])(:?[^@dDuUxXoOfeEgGcCsSpaAF])" options:0 error:nil];
    });
    return reverseTWNTokenRegex;
}

+ (NSRegularExpression *)twnTokenRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *twnTokenRegex;
    dispatch_once(&onceToken, ^{
        twnTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:[$])(:?[0-9]+)" options:0 error:nil];
    });
    return twnTokenRegex;
}

+ (NSRegularExpression *)percentNumberRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *percentNumberRegex;
    dispatch_once(&onceToken, ^{
        percentNumberRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:[%%])(:?[0-9s])" options:0 error:nil];
    });
    return percentNumberRegex;
}

- (void)assertLprojFiles:(NSArray *)lprojFiles withTranslationStringsInDirectory:(NSString *)directory haveNoMatchesWithRegex:(NSRegularExpression *)regex {
    XCTAssertNotNil(regex);
    for (NSString *lprojFileName in lprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[directory stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            NSTextCheckingResult *result = [regex firstMatchInString:localizedString options:0 range:NSMakeRange(0, localizedString.length)];
            XCTAssertNil(result, @"Invalid character in string %@", localizedString);
        }
    }
}

- (void)testiOSTranslationStringForTWNSubstitutionShortcuts {
    [self assertLprojFiles:TWNStringsTests.iOSLprojFiles withTranslationStringsInDirectory:TWNStringsTests.bundleRoot haveNoMatchesWithRegex:TWNStringsTests.twnTokenRegex];
}

- (void)testIncomingTranslationStringForReversedSubstitutionShortcuts {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.twnLocalizationsDirectory haveNoMatchesWithRegex:TWNStringsTests.reverseTWNTokenRegex];
}

- (void)testiOSTranslationStringForReversedSubstitutionShortcuts {
    [self assertLprojFiles:TWNStringsTests.iOSLprojFiles withTranslationStringsInDirectory:TWNStringsTests.bundleRoot haveNoMatchesWithRegex:TWNStringsTests.reverseTWNTokenRegex];
}

- (void)testIncomingTranslationStringForPercentTokens {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.twnLocalizationsDirectory haveNoMatchesWithRegex:TWNStringsTests.percentNumberRegex];
}

+ (NSRegularExpression *)htmlTagRegex {
    static NSRegularExpression *htmlTagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        htmlTagRegex = [NSRegularExpression regularExpressionWithPattern:@"(<[^>]*>)([^<]*)" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return htmlTagRegex;
}

- (void)testIncomingTranslationStringForHTML {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.bundleRoot haveNoMatchesWithRegex:TWNStringsTests.htmlTagRegex];
}

- (void)testIncomingTranslationStringForBracketSubstitutions {
    for (NSString *lprojFileName in TWNStringsTests.twnLprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:lprojFileName]];
            NSDictionary *pluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in stringsDict) {
                NSString *localizedString = stringsDict[key];
                if ([localizedString containsString:@"{{"]) {
                    if ([localizedString containsString:@"{{PLURAL:$"]) {
                        XCTAssertNotNil([pluralizableStringsDict objectForKey:key], @"Localizable string with PLURAL: needs an entry in the corresponding stringsdict file");
                        XCTAssertFalse([localizedString containsString:@"{{PLURAL:$2"], @"Only one plural per translation is supported at this time. You can fix this in scripts/localizations.swift.");
                    } else {
                        XCTAssertTrue(false, @"Unsupported {{ }} in localization");
                    }
                }
            }
        }
    }
}

- (void)testiOSTranslationStringForBracketSubstitutions {
    for (NSString *lprojFileName in TWNStringsTests.iOSLprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            NSDictionary *pluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in stringsDict) {
                NSString *localizedString = stringsDict[key];
                if ([localizedString containsString:@"{{"]) {
                    if ([localizedString containsString:@"{{PLURAL:%"]) {
                        XCTAssertNotNil([pluralizableStringsDict objectForKey:key], @"Localizable string with PLURAL: needs an entry in the corresponding stringsdict file");
                        XCTAssertFalse([localizedString containsString:@"{{PLURAL:%2"], @"Only one plural per translation is supported at this time. You can fix this in scripts/localizations.swift.");
                    } else {
                        XCTAssertTrue(false, @"Unsupported {{ }} in localization");
                    }
                }
            }
        }
    }
}

- (NSArray *)unbundledLprojFiles {
    NSMutableArray *files = [TWNStringsTests.twnLprojFiles mutableCopy];
    [files removeObjectsInArray:TWNStringsTests.bundledLprojFiles];
    return files;
}

- (NSArray *)unbundledLprojFilesWithTranslations {
    // unbundled lProj's containing "Localizable.strings"
    return
        [self.unbundledLprojFiles wmf_select:^BOOL(NSString *lprojFileName) {
            BOOL isDirectory = NO;
            NSString *localizableStringsFilePath =
                [[TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:lprojFileName] stringByAppendingPathComponent:@"Localizable.strings"];
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

- (void)testKeysForUnderscores {
    for (NSString *lprojFileName in TWNStringsTests.twnLprojFiles) {
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            // Keys use dash "-" separators.
            XCTAssertFalse([key containsString:@"_"]);
        }
    }
}

- (void)testMismatchedSubstitutions {

    NSString *qqqBundlePath = [TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:@"qqq.lproj"];
    NSDictionary *qqqStringsDict = [self getTranslationStringsDictFromLprogAtPath:qqqBundlePath];

    NSString *enBundlePath = [TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:@"en.lproj"];
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
}

@end
