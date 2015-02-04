//
//  CircularBitwiseRotationTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

<<<<<<< HEAD
#import "WMF_FunUtilities.h"
=======
#import "WikipediaAppUtils.h"
>>>>>>> 8fab4cb... image gallery

@interface CircularBitwiseRotationTests : XCTestCase

@end

@implementation CircularBitwiseRotationTests

- (void)testExamples
{
    NSUInteger testValue = 0b00000001;
    NSUInteger len = sizeof(testValue) * CHAR_BIT;
    XCTAssertEqual(CircularBitwiseRotation(testValue, 0), 0b001);
    XCTAssertEqual(CircularBitwiseRotation(testValue, 1), 0b00000010);
    XCTAssertEqual(CircularBitwiseRotation(testValue, 2), 0b00000100);
    XCTAssertEqual(CircularBitwiseRotation(testValue, len), 0b00000001);
    XCTAssertEqual(CircularBitwiseRotation(testValue, len + 1), 0b00000010);
}

@end
