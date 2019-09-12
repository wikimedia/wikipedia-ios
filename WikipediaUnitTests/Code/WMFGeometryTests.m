#import <XCTest/XCTest.h>
#import "WMFGeometry.h"
#import "XCTAssert+CGGeometry.h"

@interface WMFGeometryTests : XCTestCase

@end

@implementation WMFGeometryTests

- (void)testCoordinateConversionOfRegularRect {
    CGRect testUIRect = CGRectMake(50, 10, 100, 100);
    CGSize testSize = CGSizeMake(200, 200);

    CGRect ui2cgConversion = WMFConvertUICoordinateRectToCGCoordinateRectUsingSize(testUIRect, testSize);

    XCTAssertEqualRects(ui2cgConversion,
                        CGRectMake(testUIRect.origin.x,
                                   testSize.height - (testUIRect.origin.y + testUIRect.size.height),
                                   testUIRect.size.width,
                                   testUIRect.size.height));

    XCTAssertEqualRects(WMFConvertCGCoordinateRectToUICoordinateRectUsingSize(ui2cgConversion, testSize),
                        testUIRect);
}

- (void)testNormalization {
    CGRect testUIRect = CGRectMake(50, 10, 100, 100);
    CGSize testSize = CGSizeMake(200, 200);

    CGRect normalizedRect = WMFNormalizeRectUsingSize(testUIRect, testSize);
    XCTAssertEqualRectsWithAccuracy(normalizedRect,
                                    CGRectMake(testUIRect.origin.x / testSize.width,
                                               testUIRect.origin.y / testSize.height,
                                               testUIRect.size.width / testSize.width,
                                               testUIRect.size.height / testSize.height),
                                    0.0001);

    XCTAssertEqualRectsWithAccuracy(WMFDenormalizeRectUsingSize(normalizedRect, testSize), testUIRect, 0.0001);
}

- (void)testConcatTransforms {
    CGRect testUIRect = CGRectMake(50, 10, 100, 100);
    CGSize testSize = CGSizeMake(200, 200);

    CGRect convertedRect = WMFConvertUICoordinateRectToCGCoordinateRectUsingSize(testUIRect, testSize);
    CGRect convertedAndNormalizedRect = WMFNormalizeRectUsingSize(convertedRect, testSize);

    CGRect transformedRect = WMFConvertAndNormalizeCGRectUsingSize(testUIRect, testSize);

    XCTAssertEqualRectsWithAccuracy(transformedRect, convertedAndNormalizedRect, 0.0001);
}

- (void)testDistance {
    CGFloat accuracy = 0.001;
    CGPoint a = CGPointMake(0, 0);
    CGPoint b = CGPointMake(0, 0);
    CGFloat distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertEqualWithAccuracy(distance, 0, accuracy);
    a = CGPointMake(0, 0);
    b = CGPointMake(0, NAN);
    distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertTrue(isnan(distance));
    a = CGPointMake(INFINITY, 0);
    b = CGPointMake(0, 0);
    distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertTrue(isinf(distance));
    a = CGPointMake(0, 0);
    b = CGPointMake(0, 1);
    distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertEqualWithAccuracy(distance, 1, accuracy);
    a = CGPointMake(10, 0);
    b = CGPointMake(0, 0);
    distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertEqualWithAccuracy(distance, 10, accuracy);
    a = CGPointMake(2.5, 1.3);
    b = CGPointMake(24601.9, 77.4);
    distance = WMFDistanceBetweenPoints(a, b);
    XCTAssertEqualWithAccuracy(distance, 24599.5177, accuracy);
}

@end
