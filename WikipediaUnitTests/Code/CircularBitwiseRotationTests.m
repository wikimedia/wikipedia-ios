#import <XCTest/XCTest.h>
@import WMF;

@interface CircularBitwiseRotationTests : XCTestCase

@end

@implementation CircularBitwiseRotationTests

- (void)testMatchesCorrespondingPowerOfTwo {
    for (NSUInteger rotation; rotation < NSUINT_BIT; rotation++) {
        NSUInteger actualResult = flipBitsWithAdditionalRotation(1, rotation);
        // add by NSUINT_BIT_2 to model the "flipping," then modulo for rotation
        NSUInteger exponent = (rotation + NSUINT_BIT_2) % NSUINT_BIT;
        NSUInteger expectedResult = powl(2, exponent);
        XCTAssertEqual(actualResult, expectedResult,
                       @"Rotating 1 by %lu should be equal to 2^%lu (%lu). Got %lu instead",
                       (unsigned long)rotation, (unsigned long)exponent, (unsigned long)expectedResult, (unsigned long)actualResult);
    }
}

- (void)testSymmetrical {
    for (NSUInteger i; i < 50; i++) {
        NSUInteger testValue = arc4random();
        for (NSUInteger rotation; rotation < NSUINT_BIT; rotation++) {
            NSUInteger symmetricalRotation = rotation + NSUINT_BIT;
            NSUInteger original = flipBitsWithAdditionalRotation(testValue, rotation);
            NSUInteger symmetrical = flipBitsWithAdditionalRotation(testValue, symmetricalRotation);
            XCTAssertEqual(original, symmetrical,
                           @"Rotating %lu by %lu should be the same as rotating by %lu + NSUINT_BIT (%lu)."
                            "Got %lu expected %lu",
                           (unsigned long)testValue, (unsigned long)rotation, (unsigned long)rotation, (unsigned long)symmetricalRotation, (unsigned long)symmetrical, (unsigned long)original);
        }
    }
}

@end
