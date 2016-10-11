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
