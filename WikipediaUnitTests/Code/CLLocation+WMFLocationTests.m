#import <XCTest/XCTest.h>
#import "CLLocation+WMFLocation.h"

@interface CLLocation_WMFLocationTests : XCTestCase

@property (nonatomic, strong) WMFLocation empty;
@property (nonatomic, strong) WMFLocation notFull;
@property (nonatomic, strong) WMFLocation correct;
@property (nonatomic, strong) CLLocation *correctLocation;

@end

@implementation CLLocation_WMFLocationTests

- (void)setUp {
    [super setUp];
    self.correctLocation = [[CLLocation alloc] initWithLatitude: 37.783821 longitude: -122.400264];
    self.correct = @{@"lat": @37.783821, @"long": @-122.400264};
    self.notFull = @{@"lat": @37.783821};
    self.empty = @{};
}

- (void)testShouldReturnNilForEmptyDictionary {
    XCTAssertNil([CLLocation locationWithDictionary:self.empty]);
}

- (void)testShouldReturnNilForNotFullDictionary {
    XCTAssertNil([CLLocation locationWithDictionary:self.notFull]);
}

@end
