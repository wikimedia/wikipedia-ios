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
        return WMFLocalizedStringWithDefaultValue(@"timestamp-just-now", nil, nil, @"just now", @"Human-readable approximate timestamp for events in the last couple of minutes.\n{{Identical|Just now}}");
    } else if (hours < 2.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-minutes", nil, nil, @"%d minutes ago", @"Human-readable approximate timestamp for events in the last couple hours, expressed as minutes"), (int)round(minutes)];
    } else if (days < 2.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-hours", nil, nil, @"%d hours ago", @"Human-readable approximate timestamp for events in the last couple days, expressed as hours"), (int)round(hours)];
    } else if (months < 2.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-days", nil, nil, @"%d days ago", @"Human-readable approximate timestamp for events in the last couple months, expressed as days"), (int)round(days)];
    } else if (months < 24.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-months", nil, nil, @"%d months ago", @"Human-readable approximate timestamp for events in the last couple years, expressed as months"), (int)round(months)];
    } else {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-years", nil, nil, @"%d years ago", @"Human-readable approximate timestamp for events in the distant past, expressed as years"), (int)round(years)];
    }
}

@end
