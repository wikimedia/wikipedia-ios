#import "NSCalendar+WMFCommonCalendars.h"

@implementation NSCalendar (WMFCommonCalendars)

+ (instancetype)wmf_utcGregorianCalendar {
    static dispatch_once_t onceToken;
    static NSCalendar *utcGregorianCalendar;
    dispatch_once(&onceToken, ^{
        utcGregorianCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        utcGregorianCalendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return utcGregorianCalendar;
}

+ (instancetype)wmf_gregorianCalendar {
    static dispatch_once_t onceToken;
    static NSCalendar *gregorianCalendar;
    dispatch_once(&onceToken, ^{
        gregorianCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return gregorianCalendar;
}

- (NSInteger)daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSDateComponents *fromDateComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:fromDate];
    NSDateComponents *toDateComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:toDate];
    
    return [self components:NSCalendarUnitDay fromDateComponents:fromDateComponents toDateComponents:toDateComponents options:NSCalendarMatchStrictly].day;
}

@end


@implementation NSDate (WMFComparisons)

- (BOOL)wmf_isEqualToUTCDateIgnorningTime:(NSDate*)dateToCompare {
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSCalendarUnit componentFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents* components1 = [calendar components:componentFlags fromDate:self];
    NSDateComponents* components2 = [calendar components:componentFlags fromDate:dateToCompare];
    return ((components1.year == components2.year) &&
            (components1.month == components2.month) &&
            (components1.day == components2.day));
}

- (BOOL)wmf_isTodayUTC {
    return [self wmf_isEqualToUTCDateIgnorningTime:[NSDate date]];
}

@end
