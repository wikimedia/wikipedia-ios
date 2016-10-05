#import <XCTest/XCTest.h>
#import <WMFModel/WMFModel-Swift.h>

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
}

@end
