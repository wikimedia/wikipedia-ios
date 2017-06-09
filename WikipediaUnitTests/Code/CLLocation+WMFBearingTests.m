#import <XCTest/XCTest.h>
#import "CLLocation+WMFBearing.h"

@interface CLLocation_WMFBearingTests : XCTestCase

@property (nonatomic, strong) CLLocation *mosconeCenter;
@property (nonatomic, strong) CLLocation *coitTower;
@property (nonatomic, strong) CLLocation *goldenGateBridge;
@property (nonatomic, strong) CLLocation *twinPeaksSummit;
@property (nonatomic, strong) CLLocation *dogpatchBoulders;

@end

@implementation CLLocation_WMFBearingTests

- (void)setUp {
    [super setUp];
    self.mosconeCenter = [[CLLocation alloc] initWithLatitude:37.783821 longitude:-122.400264];
    self.goldenGateBridge = [[CLLocation alloc] initWithLatitude:37.809616 longitude:-122.476784];
    self.coitTower = [[CLLocation alloc] initWithLatitude:37.801904 longitude:-122.405713];
    self.twinPeaksSummit = [[CLLocation alloc] initWithLatitude:37.752959 longitude:-122.445854];
    self.dogpatchBoulders = [[CLLocation alloc] initWithLatitude:37.756303 longitude:-122.387848];
}

- (void)testShouldHaveNoBearingToSelf {
    XCTAssertEqual([self.mosconeCenter wmf_bearingToLocation:self.mosconeCenter], 0);
}

- (void)testShouldHaveANorthwestBearingFromMosconeToGoldenGate {
    CLLocationDegrees value = [self.mosconeCenter wmf_bearingToLocation:self.goldenGateBridge];
    XCTAssert(275.0 <= value && value <= 360.0, @"Expected %f to be W by NW.", value);
    XCTAssertEqualWithAccuracy(value, 293.1269271830219, 0.000001);
}

- (void)testShouldHaveNorthBearingFromMosconeToCoitTower {
    CLLocationDegrees value = [self.mosconeCenter wmf_bearingToLocation:self.coitTower];
    XCTAssert(315.0 <= value || value <= 360.0, @"Expected %f to be N by NW.", value);
    XCTAssertEqualWithAccuracy(value, 346.60434989890075, 0.1);
}

- (void)testShouldHaveSouthwestBearingFromMosconeToTwinPeaks {
    CLLocationDegrees value = [self.mosconeCenter wmf_bearingToLocation:self.twinPeaksSummit];
    XCTAssert(180.0 <= value || value <= 275, @"Expected %f to be SW.", value);
    XCTAssertEqualWithAccuracy(value, 229.4385321292595, 0.1);
}

- (void)testShouldHaveSouthEastBearingFromMosconeToDogpatch {
    CLLocationDegrees value = [self.mosconeCenter wmf_bearingToLocation:self.dogpatchBoulders];
    XCTAssert(90.0 <= value || value <= 180, @"Expected %f to be SE.", value);
    XCTAssertEqualWithAccuracy(value, 160.3669691474538, 0.1);
}

@end
