#import <XCTest/XCTest.h>
#import "NSURLComponents+WMF.h"

@interface WMFNSURLComponentsTests : XCTestCase

@end

@implementation WMFNSURLComponentsTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWMFDomain {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://en.wikipedia.org/"];
    XCTAssertEqualObjects(@"wikipedia.org", components.WMFDomain);
    XCTAssertEqualObjects(@"en", components.WMFLanguage);
}

- (void)testWMFMobileDomain {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://en.m.wikipedia.org/"];
    XCTAssertEqualObjects(@"wikipedia.org", components.WMFDomain);
    XCTAssertEqualObjects(@"en", components.WMFLanguage);
}


@end
