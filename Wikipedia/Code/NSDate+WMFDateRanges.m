//
//  NSDate+WMFDateRanges.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSDate+WMFDateRanges.h"
#import "NSDate+Utilities.h"

@implementation NSDate (WMFDateRanges)

- (NSArray<NSDate*>*)wmf_datesUntilToday {
    return [self wmf_datesUntilDate:[NSDate date]];
}

- (NSArray<NSDate*>*)wmf_datesUntilDate:(NSDate*)date {
    NSDate* laterDate                     = [date laterDate:self];
    NSDate* earlierDate                   = [date earlierDate:self];
    NSTimeInterval const secondsUntilDate = [laterDate timeIntervalSinceDate:earlierDate];
    NSInteger const daysUntilDate         = floorf(secondsUntilDate / (NSTimeInterval)D_DAY);
    NSMutableArray<NSDate*>* days         = [NSMutableArray arrayWithObject:laterDate];
    for (NSInteger d = 1; d <= daysUntilDate; d++) {
        [days addObject:[laterDate dateBySubtractingDays:d]];
    }
    return days;
}

@end
