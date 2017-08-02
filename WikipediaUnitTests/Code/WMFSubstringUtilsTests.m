#import <XCTest/XCTest.h>
#import "NSString+WMFExtras.h"

@interface WMFSubstringUtilsTests : XCTestCase

@end

@implementation WMFSubstringUtilsTests

- (void)testEmptyString {
    XCTAssert([[@"" wmf_safeSubstringToIndex:10] isEqualToString:@""]);
}

- (void)testStopsAtLength {
    XCTAssert([[@"foo" wmf_safeSubstringToIndex:5] isEqualToString:@"foo"]);
}

- (void)testGoesToIndex {
    XCTAssert([[@"foo" wmf_safeSubstringToIndex:2] isEqualToString:@"fo"]);
}

@end
