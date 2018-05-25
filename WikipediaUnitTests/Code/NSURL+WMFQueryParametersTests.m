#import <XCTest/XCTest.h>
#import "NSURL+WMFQueryParameters.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSURL_WMFQueryParametersTests : XCTestCase

@end

@implementation NSURL_WMFQueryParametersTests

- (void)testValueForQueryKeyForURLWithSingleQueryParameter {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value"];
    assertThat([url wmf_valueForQueryKey:@"key"], is(@"value"));
}

- (void)testValueForQueryKeyForURLWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value&otherkey=othervalue"];
    assertThat([url wmf_valueForQueryKey:@"otherkey"], is(@"othervalue"));
}

- (void)testValueForUnfoundQueryKeyForURLWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=value&otherkey=othervalue"];
    assertThat([url wmf_valueForQueryKey:@"nonexistentkey"], is(nilValue()));
}

- (void)testValueForQueryKeyForURLNoQueryParameters {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar"];
    assertThat([url wmf_valueForQueryKey:@"otherkey"], is(nilValue()));
}

- (void)testValueForQueryKeyForURLWithKeyButNoValueForIt {
    NSURL *url = [NSURL URLWithString:@"https://foo.org/bar?key=&otherkey=othervalue"];
    assertThat([url wmf_valueForQueryKey:@"key"], is(@""));
}

- (void)testAddingValueAndQueryKeyToURLWithoutAnyQueryKeys {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    url = [url wmf_urlWithValue:@"NEWVALUE" forQueryKey:@"KEY"];
    assertThat([url absoluteString], is(@"http://localhost:8080?KEY=NEWVALUE"));
}

- (void)testChangingValueForQueryKeyWithoutChangingOtherKeysOrValues {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?KEY=VALUE&originalSrc=http://this.jpg"];
    url = [url wmf_urlWithValue:@"NEWVALUE" forQueryKey:@"KEY"];
    assertThat([url absoluteString], is(@"http://localhost:8080?KEY=NEWVALUE&originalSrc=http://this.jpg"));
}

@end
