//
//  NSDate+WMFRelativeDate.m
//  Wikipedia
//
//  Created by Corey Floyd on 2/23/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "NSDate+WMFRelativeDate.h"

@implementation NSDate (WMFRelativeDate)

- (NSString *)wmf_relativeTimestamp {
    NSTimeInterval interval = fabs([self timeIntervalSinceNow]);
    double minutes = interval / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / (365.25 / 12.0);
    double years = months / 12.0;

    if (minutes < 2.0) {
        return MWLocalizedString(@"timestamp-just-now", nil);
    } else if (hours < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-minutes", nil), (int)round(minutes)];
    } else if (days < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-hours", nil), (int)round(hours)];
    } else if (months < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-days", nil), (int)round(days)];
    } else if (months < 24.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-months", nil), (int)round(months)];
    } else {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-years", nil), (int)round(years)];
    }
}

@end
