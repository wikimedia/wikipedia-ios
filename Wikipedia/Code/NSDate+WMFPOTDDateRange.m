//
//  NSDate+WMFPOTDDateRange.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSDate+WMFPOTDDateRange.h"
#import "NSDate+Utilities.h"

@implementation NSDate (WMFPOTDDateRange)

- (NSArray<NSDate*>*)wmf_datesUntilToday {
    NSDate* today = [NSDate date];
    NSDate* laterDate = [today laterDate:self];
    NSDate* earlierDate = [today earlierDate:self];
    NSTimeInterval const secondsUntilDate = [laterDate timeIntervalSinceDate:earlierDate];
    NSInteger const daysUntilDate = floorf(secondsUntilDate / (NSTimeInterval)D_DAY);
    NSMutableArray<NSDate*>* days = [NSMutableArray arrayWithObject:laterDate];
    for (NSInteger d = 1; d <= daysUntilDate; d++) {
        [days addObject:[laterDate dateBySubtractingDays:d]];
    }
    return days;
}

@end
