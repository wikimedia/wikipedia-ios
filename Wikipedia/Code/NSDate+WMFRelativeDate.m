#import <WMF/NSDate+WMFRelativeDate.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/NSURL+WMFLinkParsing.h>

@implementation WMFLocalizedDateFormatStrings

+ (NSString *)yearsAgoForSiteURL:(nullable NSURL *)siteURL {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-years-ago", siteURL.wmf_language, nil, @"{{PLURAL:%1$d|0=This year|Last year|%1$d years ago}}", @"Relative years ago. 0 = this year, singular = last year. %1$d will be replaced with appropriate plural for number of years ago.");
}

+ (NSString *)daysAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-days-ago", nil, nil, @"{{PLURAL:%1$d|0=Today|Yesterday|%1$d days ago}}", @"Relative days ago. 0 = today, singular = yesterday. %1$d will be replaced with appropriate plural for number of days ago.");
}

+ (NSString *)hoursAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-hours-ago", nil, nil, @"{{PLURAL:%1$d|0=Recently|%1$d hour ago|%1$d hours ago}}", @"Relative hours ago. 0 = this hour. %1$d will be replaced with appropriate plural for number of hours ago.");
}

+ (NSString *)minutesAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-minutes-ago", nil, nil, @"{{PLURAL:%1$d|0=Just now|%1$d minute ago|%1$d minutes ago}}", @"Relative minutes ago. 0 = just now. %1$d will be replaced with appropriate plural for number of minutes ago.");
}

@end

@implementation NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToLocalDate:(nonnull NSDate *)date {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSInteger days = [calendar wmf_daysFromDate:self toDate:date]; // Calendar days - less than 24 hours ago that is yesterday returns 1 day ago
    if (days > 2) {
        return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    } else if (days > 0) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self toDate:date];
        if (components.hour > 12) {
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days]; //Today or Yesterday
        } else if (components.hour > 0) {
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings hoursAgo], components.hour];
        } else {
            NSInteger minutes = MAX(0, components.minute);
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings minutesAgo], minutes];
        }
    }
}

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToNow {
    return [self wmf_localizedRelativeDateStringFromLocalDateToLocalDate:[NSDate date]];
}

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate {
    NSDate *now = [NSDate date];
    NSDate *midnightUTC = [now wmf_midnightUTCDateFromLocalDate];
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSInteger days = MAX(0, [calendar wmf_daysFromDate:self toDate:midnightUTC]);
    if (days < 2) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    }
}

@end
