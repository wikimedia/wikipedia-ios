#import <XCTest/XCTest.h>
#import "WMFNetworkUtilities.h"

@interface WMFJoinedPropertyParametersTests : XCTestCase

@end

@implementation WMFJoinedPropertyParametersTests

- (void)testNonEmptyArray {
    XCTAssert([WMFJoinedPropertyParameters(@[@"foo", @"bar", @"baz"]) isEqualToString:@"foo|bar|baz"]);
}

- (void)testUnaryArray {
    XCTAssert([WMFJoinedPropertyParameters(@[@"foo"]) isEqualToString:@"foo"]);
}

- (void)testEmptyArray {
    XCTAssert([WMFJoinedPropertyParameters(@[]) isEqualToString:@""]);
}

- (void)testNil {
    XCTAssert([WMFJoinedPropertyParameters(nil) isEqualToString:@""]);
}

@end
