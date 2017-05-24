#import "NSDate+WMFRelativeDate.h"


@interface WMFLocalizedDateFormatStrings: NSObject
@end

@implementation WMFLocalizedDateFormatStrings

+ (NSString *)daysAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-days-ago", nil, nil, @"{{PLURAL:%1$d|0=Today|Yesterday|%1$d days ago}}", @"Relative days ago. 0 = today, singular = yesterday");
}

@end

@implementation NSDate (WMFRelativeDate)

WMF_TECH_DEBT_TODO(@"Convert to the pluralized format strings above")
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
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-minutes", nil, nil, @"%1$d minutes ago", @"Human-readable approximate timestamp for events in the last couple hours, expressed as minutes"), (int)round(minutes)];
    } else if (days < 2.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-hours", nil, nil, @"%1$d hours ago", @"Human-readable approximate timestamp for events in the last couple days, expressed as hours"), (int)round(hours)];
    } else if (months < 2.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-days", nil, nil, @"%1$d days ago", @"Human-readable approximate timestamp for events in the last couple months, expressed as days"), (int)round(days)];
    } else if (months < 24.0) {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-months", nil, nil, @"%1$d months ago", @"Human-readable approximate timestamp for events in the last couple years, expressed as months"), (int)round(months)];
    } else {
        return [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"timestamp-years", nil, nil, @"%1$d years ago", @"Human-readable approximate timestamp for events in the distant past, expressed as years"), (int)round(years)];
    }
}

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate {
    NSDate *now = [NSDate date];
    NSDate *midnightUTC = [now wmf_midnightUTCDateFromLocalDate];
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSInteger days = MAX(0, [calendar wmf_daysFromDate:self toDate:midnightUTC]);
    if (days < 7) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    }
}

@end
