#import "NSDate+WMFRelativeDate.h"


@interface WMFLocalizedDateFormatStrings: NSObject
@end

@implementation WMFLocalizedDateFormatStrings

+ (NSString *)daysAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-days-ago", nil, nil, @"{{PLURAL:%1$d|0=Today|Yesterday|%1$d days ago}}", @"Relative days ago. 0 = today, singular = yesterday");
}

+ (NSString *)hoursAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-hours-ago", nil, nil, @"{{PLURAL:%1$d|0=This hour|%1$d hour ago|%1$d hours ago}}", @"Relative hours ago. 0 = this hour.");
}

+ (NSString *)minutesAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-minutes-ago", nil, nil, @"{{PLURAL:%1$d|0=Just now|%1$d minute ago|%1$d minutes ago}}", @"Relative minutes ago. 0 = just now.");
}

@end

@implementation NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateFromLocalDate {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:self toDate:now];
    
    if (components.day > 3) {
        return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    } else if (components.day > 0) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], components.day];
    } else if (components.hour > 0) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings hoursAgo], components.hour];
    } else {
        NSInteger minutes = MAX(0, components.minute);
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings minutesAgo], minutes];
    }
}

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate {
    NSDate *now = [NSDate date];
    NSDate *midnightUTC = [now wmf_midnightUTCDateFromLocalDate];
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSInteger days = MAX(0, [calendar wmf_daysFromDate:self toDate:midnightUTC]);
    if (days < 4) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    }
}

@end
