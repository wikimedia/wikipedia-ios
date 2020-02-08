#import <XCTest/XCTest.h>
#import "NSURL+WMFQueryParameters.h"

@interface NSURL_WMFQueryParametersTests : XCTestCase

@end

@implementation NSURL_WMFQueryParametersTests

- (void)testValueForQueryKeyForURLWithSingleQueryParameter {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value"];
    XCTAssertEqualObjects([url wmf_valueForQueryKey:@"key"], @"value");
}

- (void)testValueForQueryKeyForURLWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value&otherkey=othervalue"];
    XCTAssertEqualObjects([url wmf_valueForQueryKey:@"otherkey"], @"othervalue");
}

- (void)testValueForUnfoundQueryKeyForURLWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value&otherkey=othervalue"];
    XCTAssertNil([url wmf_valueForQueryKey:@"nonexistentkey"]);
}

- (void)testValueForQueryKeyForURLNoQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar"];
    XCTAssertNil([url wmf_valueForQueryKey:@"otherkey"]);
}

- (void)testValueForQueryKeyForURLWithKeyButNoValueForIt {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=&otherkey=othervalue"];
    XCTAssertEqualObjects([url wmf_valueForQueryKey:@"key"], @"");
}

- (void)testAddingValueAndQueryKeyToURLWithoutAnyQueryKeys {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    url = [url wmf_urlWithValue:@"NEWVALUE" forQueryKey:@"KEY"];
    XCTAssertEqualObjects([url absoluteString], @"http://localhost:8080?KEY=NEWVALUE");
}

- (void)testChangingValueForQueryKeyWithoutChangingOtherKeysOrValues {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?KEY=VALUE&originalSrc=http://this.jpg"];
    url = [url wmf_urlWithValue:@"NEWVALUE" forQueryKey:@"KEY"];
    XCTAssertEqualObjects([url absoluteString], @"http://localhost:8080?KEY=NEWVALUE&originalSrc=http://this.jpg");
}

@end
