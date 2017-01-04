#import <XCTest/XCTest.h>
#import <WMF/WMF-Swift.h>

@interface WMFLocaleTests : XCTestCase

@end

@implementation WMFLocaleTests

- (void)testLocaleHeaders {
    NSArray *languages = [NSLocale wmf_uniqueLanguageCodesForLanguages:@[@"en-US", @"zh-Hans-US", @"zh-Hant-US", @"zh-Hant-TW", @"en-GB"]];
    NSArray *expectedResult = @[@"en-us", @"zh-hans", @"zh-hant", @"zh-tw", @"en-gb"];
    XCTAssert([languages isEqualToArray:expectedResult]);

    NSString *header = [NSLocale wmf_acceptLanguageHeaderForLanguageCodes:languages];
    XCTAssert([header isEqualToString:@"en-us, zh-hans;q=0.8, zh-hant;q=0.6, zh-tw;q=0.4, en-gb;q=0.2"]);
}

- (void)testZHHeaders {
    NSArray *languages = [NSLocale wmf_uniqueLanguageCodesForLanguages:@[@"zh-Hans-CN", @"zh-Hans-SG", @"zh-Hant-MO", @"zh-Hant-TW", @"zh-Hant-HK"]];
    NSArray *expectedResult = @[@"zh-cn", @"zh-sg", @"zh-mo", @"zh-tw", @"zh-hk"];
    XCTAssert([languages isEqualToArray:expectedResult]);

    NSString *header = [NSLocale wmf_acceptLanguageHeaderForLanguageCodes:languages];
    XCTAssert([header isEqualToString:@"zh-cn, zh-sg;q=0.8, zh-mo;q=0.6, zh-tw;q=0.4, zh-hk;q=0.2"]);
}

@end
