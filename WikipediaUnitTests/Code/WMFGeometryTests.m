//
//  WMFGeometryTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@end
