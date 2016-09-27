#import <XCTest/XCTest.h>
#import <WMFModel/WMFModel-Swift.h>

@interface WMFLocaleTests : XCTestCase

@end

@implementation WMFLocaleTests

- (void)testLocaleHeaders {
    NSArray *languages = [NSLocale wmf_uniqueLanguageCodesForLanguages:@[@"en-US", @"zh-Hans-US", @"zh-Hant-US", @"en-GB"]];
    NSArray *expectedResult = @[@"en", @"zh-hans", @"zh-hant"];
    XCTAssert([languages isEqualToArray:expectedResult]);
    
    NSString *header = [NSLocale wmf_acceptLanguageHeaderForLanguageCodes:languages];
    XCTAssert([header isEqualToString:@"en, zh-hans;q=0.67, zh-hant;q=0.33"]);
}

@end
