#import <XCTest/XCTest.h>
#import "WMFTestConstants.h"

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
    NSString *sourceRootPath = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:WMFSourceRootDirKey];
    return [sourceRootPath stringByAppendingPathComponent:@"Wikipedia/iOS Native Localizations"];
}

+ (NSString *)twnLocalizationsDirectory {
    NSString *sourceRootPath = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:WMFSourceRootDirKey];
    return [sourceRootPath stringByAppendingPathComponent:@"Wikipedia/Localizations"];
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

- (void)testLprojCount {
    XCTAssert(TWNStringsTests.iOSLprojFiles.count > 0);
    XCTAssert(TWNStringsTests.twnLprojFiles.count > 0);
}

+ (NSRegularExpression *)reverseiOSTokenRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *reverseiOSTokenRegex;
    dispatch_once(&onceToken, ^{
        reverseiOSTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"(:?[^%%])(:?[0-9]+)(?:[$])(:?[^@dDuUxXoOfeEgGcCsSpaAF])" options:0 error:nil];
    });
    return reverseiOSTokenRegex;
}

+ (NSRegularExpression *)reverseTWNTokenRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *reverseTWNTokenRegex;
    dispatch_once(&onceToken, ^{
        reverseTWNTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"(:?[0-9])(?:[$])(:?[^0-9])" options:0 error:nil];
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
        percentNumberRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!%)(?:[%%])(:?[0-9s])" options:0 error:nil];
    });
    return percentNumberRegex;
}

+ (NSRegularExpression *)iOSTokenRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *iOSTokenRegex;
    dispatch_once(&onceToken, ^{
        iOSTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"%([0-9]*)\\$?([@dDuUxXoOfeEgGcCsSpaAF])" options:0 error:nil];
    });
    return iOSTokenRegex;
}

+ (NSRegularExpression *)singlePercentRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *singlePercentRegex;
    dispatch_once(&onceToken, ^{
        singlePercentRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!%)%(?![%@d])" options:0 error:nil];
    });
    return singlePercentRegex;
}

- (void)assertLprojFiles:(NSArray *)lprojFiles withTranslationStringsInDirectory:(NSString *)directory haveNoMatchesWithRegex:(NSRegularExpression *)regex {
    XCTAssertNotNil(regex);
    for (NSString *lprojFileName in lprojFiles) {
        if (![TWNStringsTests localeForLprojFilenameIsAvailableOniOS:lprojFileName]) {
            continue;
        }
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[directory stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            NSTextCheckingResult *result = [regex firstMatchInString:localizedString options:0 range:NSMakeRange(0, localizedString.length)];
            XCTAssertNil(result, @"Invalid character in string: %@ for key: %@ in locale: %@", localizedString, key, lprojFileName);
        }
    }
}

- (void)assertLprojFiles:(NSArray *)lprojFiles withTranslationStringsInDirectory:(NSString *)directory doesNotContain:(NSString *)banned {
    XCTAssertNotNil(banned);
    NSString *bannedUpper = [banned uppercaseString];
    for (NSString *lprojFileName in lprojFiles) {
        if (![TWNStringsTests localeForLprojFilenameIsAvailableOniOS:lprojFileName]) {
            continue;
        }
        NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[directory stringByAppendingPathComponent:lprojFileName]];
        for (NSString *key in stringsDict) {
            NSString *localizedString = stringsDict[key];
            BOOL doesContainBannedString = [[localizedString uppercaseString] containsString:bannedUpper];
            XCTAssertFalse(doesContainBannedString, @"Invalid substring %@ found in: %@ for key: %@ in locale: %@", banned, localizedString, key, lprojFileName);
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
    [self assertLprojFiles:TWNStringsTests.iOSLprojFiles withTranslationStringsInDirectory:TWNStringsTests.bundleRoot haveNoMatchesWithRegex:TWNStringsTests.reverseiOSTokenRegex];
}

- (void)testIncomingTranslationStringForPercentTokens {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.twnLocalizationsDirectory haveNoMatchesWithRegex:TWNStringsTests.percentNumberRegex];
}

// Note: This test should fail for any incoming strings that have a single percent sign, but only if it is NOT followed by @ or d.
// Examples:
// "100% of my donation" should fail (string needs to be "100%% of my donation" to avoid crash)
// "Wszystkie karty %@ są ukryte" should pass
// "Zaviedli sme limit %d článkov na zoznam na prečítanie" should also pass
- (void)testIncomingTranslationStringForSinglePercentSigns {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.twnLocalizationsDirectory haveNoMatchesWithRegex:TWNStringsTests.singlePercentRegex];
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

- (void)testIncomingTranslationStringForNBSP {
    [self assertLprojFiles:TWNStringsTests.twnLprojFiles withTranslationStringsInDirectory:TWNStringsTests.bundleRoot doesNotContain:@"&nbsp;"];
}

- (void)testIncomingTranslationStringForBracketSubstitutions {
    for (NSString *lprojFileName in TWNStringsTests.twnLprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            NSDictionary *pluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in stringsDict) {
                NSString *localizedString = stringsDict[key];
                if ([localizedString containsString:@"{{"]) {
                    NSString *lowercaseString = localizedString.lowercaseString;
                    if ([lowercaseString containsString:@"{{plural:"]) {
                        XCTAssertNotNil([pluralizableStringsDict objectForKey:key], @"Localizable string %@ in %@ with PLURAL: needs an entry in the corresponding stringsdict file. This likely means that this language's Localizable.stringsdict hasn't been added to the project yet.", key, lprojFileName);
                    } else if (![lowercaseString containsString:@"{{formatnum:$"]) {
                        XCTAssertTrue(false, @"%@ in %@ has unsupported {{ }} in localization.", key, lprojFileName);
                    }
                }
            }
        }
    }
}

- (void)testiOSTranslationStringForBracketSubstitutionsAndMismatchedTokens {
    NSDictionary *enStrings = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:@"en.lproj"]];
    NSMutableDictionary *enTokensByKey = [NSMutableDictionary dictionaryWithCapacity:enStrings.count];
    for (NSString *lprojFileName in TWNStringsTests.iOSLprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary *stringsDict = [self getTranslationStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            NSDictionary *pluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in stringsDict) {
                NSString *localizedString = stringsDict[key];
                if ([localizedString containsString:@"{{"]) {
                    NSString *lowercaseString = localizedString.lowercaseString;
                    if ([lowercaseString containsString:@"{{plural:%"]) {
                        XCTAssertNotNil([pluralizableStringsDict objectForKey:key], @"Localizable string %@ in %@ with PLURAL: needs an entry in the corresponding stringsdict file. This likely means that this language's Localizable.stringsdict hasn't been added to the project yet.", key, lprojFileName);

                    } else {
                        XCTAssertTrue(false, @"Unsupported {{ }} in localization");
                    }
                }

                NSMutableDictionary *localizedTokens = [NSMutableDictionary new];
                NSRegularExpression *tokenRegex = [TWNStringsTests iOSTokenRegex];
                [tokenRegex enumerateMatchesInString:localizedString
                                             options:0
                                               range:NSMakeRange(0, localizedString.length)
                                          usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                              NSString *tokenKey = [tokenRegex replacementStringForResult:result inString:localizedString offset:0 template:@"$1"];
                                              if ([tokenKey isEqualToString:@""]) {
                                                  tokenKey = @"1";
                                                  XCTAssertNil(localizedTokens[tokenKey], @"There can only be one unordered token in a localization string. Switch to ordered tokens:\n%@\n%@", key, localizedString);
                                              }
                                              NSString *value = [tokenRegex replacementStringForResult:result inString:localizedString offset:0 template:@"$2"];
                                              localizedTokens[tokenKey] = value;
                                          }];

                NSString *enString = enStrings[key];
                NSMutableDictionary *enTokens = enTokensByKey[key];
                if (enString) {
                    if (!enTokens) {
                        enTokens = [NSMutableDictionary new];
                        [tokenRegex enumerateMatchesInString:enString
                                                     options:0
                                                       range:NSMakeRange(0, enString.length)
                                                  usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                      NSString *tokenKey = [tokenRegex replacementStringForResult:result inString:enString offset:0 template:@"$1"];
                                                      if ([tokenKey isEqualToString:@""]) {
                                                          tokenKey = @"1";
                                                          XCTAssertNil(enTokens[tokenKey], @"There can only be one unordered token in a localization string. Switch to ordered tokens:\n%@\n%@", key, enString);
                                                      }
                                                      NSString *value = [tokenRegex replacementStringForResult:result inString:enString offset:0 template:@"$2"];
                                                      enTokens[tokenKey] = value;
                                                  }];
                        enTokensByKey[key] = enTokens;
                    }

                    XCTAssertEqualObjects(localizedTokens, enTokens, @"%@ translation for %@ has incorrect tokens:\n%@\n%@", lprojFileName, key, enString, localizedString);
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

+ (NSSet<NSString *> *)supportedLocales {
    static dispatch_once_t onceToken;
    static NSSet<NSString *> *supportedLocales;
    dispatch_once(&onceToken, ^{
        NSArray *lowercaseAvailableLocales = [[NSLocale availableLocaleIdentifiers] wmf_map:^id(NSString *locale) {
            return [locale lowercaseString];
        }];
        supportedLocales = [NSSet setWithArray:lowercaseAvailableLocales];
    });
    return supportedLocales;
}

+ (BOOL)localeForLprojFilenameIsAvailableOniOS:(NSString *)lprojFileName {
    NSString *localeIdentifier = [[lprojFileName substringToIndex:lprojFileName.length - 6] lowercaseString]; // remove .lproj suffix
    return [[TWNStringsTests supportedLocales] containsObject:localeIdentifier];
}

- (void)testAllSupportedTranslatedLanguagesWereAddedToProjectLocalizations {
    // Fails if any supported languages have TWN translations (in "Wikipedia/Localizations/Localizable.strings") but are
    // not yet bundled in the project.
    // So, if this test fails, the languages listed will need to be added these to the project's localizations.
    // To do this:
    // 1. Go to the project editor, select the project name under Project, and click Info. Under Localizations, click the Add button (+), then choose a language combination from the pop-up menu.
    // 2. Then in the project navigator, click the "Localizable" file in the "Localizations" group, and add a checkmark to your language in the file inspector.
    // If you get warnings about existing localizations in previous two steps, choose option to use existing files. You might need to delete the new language folder under iOS Native Localizations BEFORE adding the language in the project editor.
    NSArray *files = [self.unbundledLprojFilesWithTranslations mutableCopy];
    for (NSString *file in files) {
        XCTAssert(![TWNStringsTests localeForLprojFilenameIsAvailableOniOS:file], @"Missing supported translation for %@", file);
    }
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

// Translators need context for all substitutions. If a string has any substitutions, such as "$1" or "$2" etc, the string's comment needs to explain what will be substituted in place of "$1", "$2" etc.
- (void)testiOSTranslationCommentsForMentionOfEachSubstitution {
    NSDictionary *enStrings = [self getDictFromPListAtPath:[[TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:@"en.lproj"] stringByAppendingPathComponent:@"Localizable.strings"]];
    NSDictionary *qqqStrings = [self getDictFromPListAtPath:[[TWNStringsTests.twnLocalizationsDirectory stringByAppendingPathComponent:@"qqq.lproj"] stringByAppendingPathComponent:@"Localizable.strings"]];
    for (NSString *enKey in enStrings) {
        // This test assumes each EN key is also present in QQQ.
        XCTAssertTrue([qqqStrings valueForKey:enKey], @"Expected en key in qqq");

        NSString *enString = enStrings[enKey];
        NSString *qqqString = qqqStrings[enKey];
        NSArray<NSTextCheckingResult *> *enSubstitutionMatches = [TWNStringsTests.twnTokenRegex matchesInString:enString options:0 range:NSMakeRange(0, enString.length)];
        NSArray<NSTextCheckingResult *> *qqqSubstitutionMatches = [TWNStringsTests.twnTokenRegex matchesInString:qqqString options:0 range:NSMakeRange(0, qqqString.length)];

        for (NSTextCheckingResult *enMatch in enSubstitutionMatches) {
            NSString *enMatchString = [enString substringWithRange:enMatch.range];
            BOOL didFindEnMatchStringAtLeastOnceInQQQMatchString = NO;

            for (NSTextCheckingResult *qqqMatch in qqqSubstitutionMatches) {
                NSString *qqqMatchString = [qqqString substringWithRange:qqqMatch.range];
                if ([qqqMatchString isEqualToString:enMatchString]) {
                    didFindEnMatchStringAtLeastOnceInQQQMatchString = YES;
                    break;
                }
            }

            XCTAssertTrue(didFindEnMatchStringAtLeastOnceInQQQMatchString, @"\n\tExpected each substitution (i.e. \"$1\") in string is mentioned at least once in its comment.\n\t\tString: \"%@\"\n\t\tComment: \"%@\"\n\t\tKey: \"%@\"\n\n", [enString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"], [qqqString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"], enKey);

            if (!didFindEnMatchStringAtLeastOnceInQQQMatchString) {
                // No need keep testing if a string already failed our assertion once.
                break;
            }
        }
    }
}

// Translators have been know to add "{{plural..." syntax to strings which don't yet have "{{plural..." in EN, which means the string won't be correctly resolved.
- (void)testIncomingTranslationStringForBracketSubstitutionsNotPresentInEN {
    NSDictionary *enPluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:@"en.lproj"]];
    for (NSString *lprojFileName in TWNStringsTests.twnLprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"] && ![lprojFileName isEqualToString:@"en.lproj"]) {
            NSDictionary *translationPluralizableStringsDict = [self getPluralizableStringsDictFromLprogAtPath:[TWNStringsTests.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString *key in translationPluralizableStringsDict) {
                XCTAssertNotNil([enPluralizableStringsDict objectForKey:key], @"\n\n\"%@\" translation containing plurals syntax received for \"%@\" string. The original EN string...\n\thttps://translatewiki.net/w/i.php?title=Wikimedia:Wikipedia-ios-%@/en&action=edit\n...doesn't have (or possibly need) plural syntax - either plural syntax will need to be added to the EN string or the translation...\n\thttps://translatewiki.net/w/i.php?title=Wikimedia:Wikipedia-ios-%@/%@&action=edit\n...will need to be updated to remove plural syntax.\n(Note: after loading the link above you can tap the \"Ask question\" button to pre-fill a Phabricator ticket for asking `i18n` folks for assistance for this string)\n\n", lprojFileName, key, key, key, [lprojFileName stringByReplacingOccurrencesOfString:@".lproj" withString:@""]);
            }
        }
    }
}

- (void)tearDown {
    [super tearDown];
}

@end
