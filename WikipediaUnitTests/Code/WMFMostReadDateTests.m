//
//  WMFMostReadDateTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

@import Nimble;
@import Quick;

#import "NSDate+WMFMostReadDate.h"
#import "NSTimeZone+WMFTestingUtils.h"
#import "NSCalendar+WMFCommonCalendars.h"

QuickSpecBegin(WMFMostReadDateTests)

    resetTimeZoneAfterEach();

describe(@"most read date", ^{
  it(@"should always be 1 or 2 days before the current date", ^{
    [NSTimeZone wmf_forEachKnownTimeZoneAsDefault:^{
      NSDate *bestDate = [NSDate wmf_latestMostReadDataWithLikelyAvailableData];
      expect(@([bestDate timeIntervalSinceNow])).to(beLessThan(@(-86400)));
      expect(@([bestDate timeIntervalSinceNow])).to(beGreaterThan(@(-86400 * 3)));
    }];
  });

  it(@"should be yesterday if the hour is >= threshold, otherwise day before yesterday", ^{
    for (int i = 0; i < 24; i++) {
        NSDate *nowAtHour =
            [[NSCalendar wmf_utcGregorianCalendar]
                dateBySettingHour:i
                           minute:0
                           second:0
                           ofDate:[NSDate date]
                          options:NSCalendarMatchStrictly];
        NSDate *bestDate = [nowAtHour wmf_bestMostReadFetchDate];

        NSInteger bestDateDaysSinceNowAtHour = [[NSCalendar wmf_utcGregorianCalendar]
                                                   components:NSCalendarUnitDay
                                                     fromDate:nowAtHour
                                                       toDate:bestDate
                                                      options:NSCalendarMatchStrictly]
                                                   .day;
        NSNumber *expectedDayDelta = i >= WMFPageviewDataAvailabilityThreshold ? @(-1) : @(-2);
        expect(@(bestDateDaysSinceNowAtHour)).to(equal(expectedDayDelta));
    }
  });
});

QuickSpecEnd
