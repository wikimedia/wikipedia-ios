#import <XCTest/XCTest.h>
@import WMF.WMFMath;

// Redefine assert macro for testing WMFStrictClamp
#undef assert
#define assert(...) (void)(didAssert = YES)

static BOOL didAssert = NO;

@interface WMFMathTests : XCTestCase

@end

@implementation WMFMathTests

- (void)setUp {
    [super setUp];
    didAssert = NO;
}

- (void)testRounding {
    XCTAssertEqual(0.5, WMFFlooredPercentage(0.5));
    XCTAssertEqual(0.0, WMFFlooredPercentage(0.0));
    XCTAssertEqual(0.59, WMFFlooredPercentage(0.59));
    XCTAssertEqual(0.59, WMFFlooredPercentage(0.599));
}

- (void)testStrictClampReturnsValueIfWithinBounds {
    XCTAssertEqual(WMFStrictClamp(0, 1, 2), 1);
}

- (void)testStrictClampReturnsMinWhenOutsideLowerBound {
    XCTAssertEqual(WMFStrictClamp(0, -1, 2), 0);
}

- (void)testStrictClampReturnsMaxWhenOutsideUpperBound {
    XCTAssertEqual(WMFStrictClamp(0, 3, 2), 2);
}

- (void)testStrictClampAssertsWhenGivenInvalidBounds {
    WMFStrictClamp(2, 1, 0);
    XCTAssertTrue(didAssert);
}

- (void)testClampReturnsSameResultWhenBoundsAreReversed {
    XCTAssertEqual(WMFClamp(2, 1, 0), WMFClamp(0, 1, 2));
}

- (void)testRadiansToClock {
    XCTAssertEqual(WMFRadiansToClock(0), 12);
    XCTAssertEqual(WMFRadiansToClock(M_PI / 6), 1);
    XCTAssertEqual(WMFRadiansToClock(M_PI / 2), 3);
    XCTAssertEqual(WMFRadiansToClock(M_PI), 6);
    XCTAssertEqual(WMFRadiansToClock(1.5 * M_PI), 9);
    XCTAssertEqual(WMFRadiansToClock(2 * M_PI), 12);
    XCTAssertEqual(WMFRadiansToClock(-M_PI / 2), 9);
    XCTAssertEqual(WMFRadiansToClock(-M_PI), 6);
    XCTAssertEqual(WMFRadiansToClock(4 * M_PI), 12);
    XCTAssertEqual(WMFRadiansToClock(-3.5 * M_PI), 3);
    XCTAssertEqual(WMFRadiansToClock(M_PI / 6 - 0.001), 1);
}

@end
