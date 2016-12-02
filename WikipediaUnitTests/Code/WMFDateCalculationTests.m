#import <XCTest/XCTest.h>
#import "NSCalendar+WMFCommonCalendars.h"

@interface WMFDateCalculationTests : XCTestCase

@end

@implementation WMFDateCalculationTests

- (void)testDaysBetweenUnder24Hours {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 2;
    toDateComponents.hour = 9;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSInteger days = [calendar wmf_daysFromDate:fromDate toDate:toDate];
    XCTAssertTrue(days == 1);
}

- (void)testDaysBetweenOver24Hours {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 9;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 2;
    toDateComponents.hour = 12;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSInteger days = [calendar wmf_daysFromDate:fromDate toDate:toDate];
    XCTAssertTrue(days == 1);
}

- (void)testDaysBetweenUnder48Hours {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 3;
    toDateComponents.hour = 9;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSInteger days = [calendar wmf_daysFromDate:fromDate toDate:toDate];
    XCTAssertTrue(days == 2);
}

- (void)testDaysBetweenWrapMonths {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 9;
    fromDateComponents.day = 30;
    fromDateComponents.hour = 9;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 8;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSInteger days = [calendar wmf_daysFromDate:fromDate toDate:toDate];
    XCTAssertTrue(days == 1);
}

@end
