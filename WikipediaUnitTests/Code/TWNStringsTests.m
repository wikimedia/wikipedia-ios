
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface TWNStringsTests : XCTestCase

@property (strong, nonatomic) NSArray* lprojFiles;
@property (strong, nonatomic) NSString* bundleRoot;

@end

@implementation TWNStringsTests

- (void)setUp {
    [super setUp];
    self.bundleRoot = [[NSBundle mainBundle] bundlePath];
    self.lprojFiles = [self getLprogFiles];
}

- (NSArray*)getLprogFiles {
    return [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.bundleRoot error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension='lproj'"]];
}

- (NSDictionary*)getTranslationStringsDictFromLprogAtPath:(NSString*)lprojPath {
    NSString* stringsFilePath = [lprojPath stringByAppendingPathComponent:@"Localizable.strings"];
    BOOL isDirectory          = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:stringsFilePath isDirectory:&isDirectory]) {
        return [NSDictionary dictionaryWithContentsOfFile:stringsFilePath];
    }
    return nil;
}

- (void)test_lproj_count {
    assertThat(@(self.lprojFiles.count), is(greaterThan(@(0))));
}

- (void)test_incoming_translation_string_for_reversed_substitution_shortcuts {
    for (NSString* lprojFileName in self.lprojFiles) {
        NSDictionary* stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString* key in stringsDict) {
            NSString* localizedString = stringsDict[key];
            assertThat(localizedString, isNot(containsSubstring(@"1$")));
            assertThat(localizedString, isNot(containsSubstring(@"2$")));
            assertThat(localizedString, isNot(containsSubstring(@"3$")));
            assertThat(localizedString, isNot(containsSubstring(@"4$")));
            assertThat(localizedString, isNot(containsSubstring(@"5$")));
        }
    }
}

- (void)test_incoming_translation_string_for_html {
    for (NSString* lprojFileName in self.lprojFiles) {
        NSDictionary* stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
        for (NSString* key in stringsDict) {
            NSString* localizedString = stringsDict[key];
            assertThat(localizedString, isNot(stringContainsInOrder(@"<", @">", nil)));
            assertThat(localizedString, isNot(containsSubstring(@"&nbsp")));
        }
    }
}

- (void)test_incoming_translation_string_for_bracket_substitutions {
    for (NSString* lprojFileName in self.lprojFiles) {
        if (![lprojFileName isEqualToString:@"qqq.lproj"]) {
            NSDictionary* stringsDict = [self getTranslationStringsDictFromLprogAtPath:[self.bundleRoot stringByAppendingPathComponent:lprojFileName]];
            for (NSString* key in stringsDict) {
                NSString* localizedString = stringsDict[key];
                assertThat(localizedString, isNot(stringContainsInOrder(@"{{", @"}}", nil)));
            }
        }
    }
}

- (void)tearDown {
    [super tearDown];
    self.lprojFiles = nil;
    self.bundleRoot = nil;
}

@end
