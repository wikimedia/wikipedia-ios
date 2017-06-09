#import <XCTest/XCTest.h>
#import "NSString+WMFExtras.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSubstringUtilsTests : XCTestCase

@end

@implementation WMFSubstringUtilsTests

- (void)testEmptyString {
    assertThat([@"" wmf_safeSubstringToIndex:10], is(equalTo(@"")));
}

- (void)testStopsAtLength {
    assertThat([@"foo" wmf_safeSubstringToIndex:5], is(equalTo(@"foo")));
}

- (void)testGoesToIndex {
    assertThat([@"foo" wmf_safeSubstringToIndex:2], is(equalTo(@"fo")));
}

@end
