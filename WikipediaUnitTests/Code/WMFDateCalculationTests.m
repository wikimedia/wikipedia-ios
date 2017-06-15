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

- (void)testComponentsBetweenUnder24Hours {
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
    NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fromDate toDate:toDate];
    XCTAssertTrue(components.hour == 21);
}

- (void)testComponentsBetweenOver24Hours {
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
    NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fromDate toDate:toDate];
    XCTAssertTrue(components.day == 1);
}

- (void)testComponentsBetweenUnder48Hours {
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
    NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fromDate toDate:toDate];
    XCTAssertTrue(components.day == 1);
    XCTAssertTrue(components.hour == 21);
}

- (void)testComponentsBetweenWrapMonths {
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
    NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fromDate toDate:toDate];
    XCTAssertTrue(components.day == 0);
    XCTAssertTrue(components.hour == 23);
}

- (void)testRelativeDateStringYesterday {
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
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"Yesterday"]);
}

- (void)testRelativeDateStringTwoDaysAgo {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 9;
    fromDateComponents.day = 29;
    fromDateComponents.hour = 9;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 8;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"2 days ago"]);
}

- (void)testRelativeDateStringDifferentDayUnder24Hours {
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
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"Yesterday"]);
}

- (void)testRelativeDateStringSameDayUnder24Hours {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 1;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 23;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"Today"]);
}

- (void)testRelativeDateStringSameDayUnder12Hours {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 15;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"3 hours ago"]);
}

- (void)testRelativeDateStringSameDayUnder12HoursSingular {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 13;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"1 hour ago"]);
}

- (void)testRelativeDateStringSameDayUnder1Hour {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;
    fromDateComponents.minute = 30;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 12;
    toDateComponents.minute = 35;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"5 minutes ago"]);
}

- (void)testRelativeDateStringSameDayUnder1Minute {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    NSDateComponents *fromDateComponents = [[NSDateComponents alloc] init];
    fromDateComponents.year = 2016;
    fromDateComponents.month = 10;
    fromDateComponents.day = 1;
    fromDateComponents.hour = 12;
    fromDateComponents.minute = 30;
    fromDateComponents.second = 30;

    NSDateComponents *toDateComponents = [[NSDateComponents alloc] init];
    toDateComponents.year = 2016;
    toDateComponents.month = 10;
    toDateComponents.day = 1;
    toDateComponents.hour = 12;
    toDateComponents.minute = 30;
    toDateComponents.second = 35;

    NSDate *fromDate = [calendar dateFromComponents:fromDateComponents];
    NSDate *toDate = [calendar dateFromComponents:toDateComponents];
    NSString *string = [fromDate wmf_localizedRelativeDateStringFromLocalDateToLocalDate:toDate];
    XCTAssert([string isEqualToString:@"Just now"]);
}

@end
