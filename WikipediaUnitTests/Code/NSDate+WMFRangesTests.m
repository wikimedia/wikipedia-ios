//
//  NSDate+WMFRangesTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/4/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;
#import <NSDate-Extensions/NSDate+Utilities.h>
#import "NSDate+WMFDateRanges.h"

QuickSpecBegin(NSDate_WMFRangesTests)

    static NSDate *today;
static NSDate *startOfToday;
static NSDate *yesterday;
static NSDate *tomorrow;

beforeSuite(^{
  today = [NSDate date];
  startOfToday = [today dateAtStartOfDay];
  yesterday = [today dateBySubtractingDays:1];
  tomorrow = [today dateByAddingDays:1];
});

describe(@"base case", ^{
  it(@"should return [today] when asking for the dates until itself", ^{
    expect([today wmf_datesUntilDate:today]).to(equal(@[ today ]));
  });
  it(@"should return [yesterday] when asking for the dates until itself", ^{
    expect([yesterday wmf_datesUntilDate:yesterday]).to(equal(@[ yesterday ]));
  });
  it(@"should return [tomorrow] when asking for the dates until itself", ^{
    expect([tomorrow wmf_datesUntilDate:tomorrow]).to(equal(@[ tomorrow ]));
  });
});

describe(@"later dates", ^{
  it(@"should return later today when asking for the dates between earlier today and later today", ^{
    expect([startOfToday wmf_datesUntilDate:today]).to(equal(@[ today ]));
  });
  it(@"should return expected dates from yesterday until tomorrow in descending order", ^{
    expect([yesterday wmf_datesUntilDate:tomorrow]).to(equal(@[ tomorrow, today, yesterday ]));
  });
});

describe(@"earlier dates", ^{
  it(@"should return later today when asking for the dates between later today and earlier today", ^{
    expect([today wmf_datesUntilDate:startOfToday]).to(equal(@[ today ]));
  });
  it(@"should return expected dates from tomorrow until yesterday in descending order", ^{
    expect([tomorrow wmf_datesUntilDate:yesterday]).to(equal(@[ tomorrow, today, yesterday ]));
  });
});

describe(@"relative times", ^{
  it(@"should return times relative to the later date", ^{
    expect([tomorrow wmf_datesUntilDate:[startOfToday dateBySubtractingDays:1]])
        .to(equal(@[ tomorrow, today, yesterday ]));
  });
});

QuickSpecEnd
