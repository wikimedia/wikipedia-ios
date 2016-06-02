#import <XCTest/XCTest.h>
#import "NSURLComponents+WMFURLParsing.h"

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
    NSURLComponents* components = [NSURLComponents componentsWithString:@"https://en.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", components.wmf_domain);
    XCTAssertEqualObjects(@"en", components.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", components.wmf_title);
}

- (void)testWMFMobileDomain {
    NSURLComponents* components = [NSURLComponents componentsWithString:@"https://en.m.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", components.wmf_domain);
    XCTAssertEqualObjects(@"en", components.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", components.wmf_title);
}

@end
