//
//  NSDate+WMFPOTDTitleTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/4/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "NSDate+WMFPOTDTitle.h"
#import "NSDate+Utilities.h"

static inline NSString* expectedPOTDTitleStringForYearMonthDay(int year, int month, int day) {
    return [NSString stringWithFormat:@"%@/%d-%02d-%02d", WMFPOTDTitlePrefix, year, month, day];
}

QuickSpecBegin(NSDate_WMFPOTDTitleTests)

WMF_TECH_DEBT_TODO(test this to ensure it is not affected by system calendar)

static NSDate * testDate;
static int const year  = 2015;
static int const month = 2;
static int const day   = 2;

beforeSuite(^{
    NSDateComponents* testDateComponents = [[NSDateComponents alloc] init];
    testDateComponents.calendar = [NSCalendar currentCalendar];
    testDateComponents.day = day;
    testDateComponents.month = month;
    testDateComponents.year = year;

    testDate = testDateComponents.date;
});

describe(@"example dates", ^{
    it(@"should return the expected title for the test date", ^{
        expect([testDate wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year, month, day)));
    });

    it(@"should return the expected title for the day before the test date", ^{
        expect([[testDate dateBySubtractingDays:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year, month, day - 1)));
    });

    it(@"should return the expected title for the day after the test date", ^{
        expect([[testDate dateByAddingDays:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year, month, day + 1)));
    });

    it(@"should return the expected title for the month before the test date", ^{
        expect([[testDate dateBySubtractingMonths:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year, month - 1, day)));
    });

    it(@"should return the expected title for the month after the test date", ^{
        expect([[testDate dateByAddingMonths:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year, month + 1, day)));
    });

    it(@"should return the expected title for the year before the test date", ^{
        expect([[testDate dateBySubtractingYears:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year - 1, month, day)));
    });

    it(@"should return the expected title for the year after the test date", ^{
        expect([[testDate dateByAddingYears:1] wmf_picOfTheDayPageTitle])
        .to(equal(expectedPOTDTitleStringForYearMonthDay(year + 1, month, day)));
    });
});

QuickSpecEnd
