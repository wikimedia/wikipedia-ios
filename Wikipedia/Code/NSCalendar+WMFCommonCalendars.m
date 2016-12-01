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

- (NSInteger)wmf_daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    if (!fromDate || !toDate) {
        return 0;
    }

    NSDateComponents *fromDateComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:fromDate];
    NSDateComponents *toDateComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:toDate];

    if (!fromDateComponents || !toDateComponents) {
        return 0;
    }

    return [self components:NSCalendarUnitDay fromDateComponents:fromDateComponents toDateComponents:toDateComponents options:NSCalendarMatchStrictly].day;
}

@end

@implementation NSDate (WMFComparisons)

- (BOOL)wmf_isTodayUTC {
    return [[NSCalendar wmf_utcGregorianCalendar] isDateInToday:self];
}

- (BOOL)wmf_UTCDateIsSameDateAsLocalDate:(NSDate *)date {
    NSCalendar *localCalendar = [NSCalendar wmf_gregorianCalendar];
    NSDateComponents *localComponents = [localCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    localComponents.timeZone = nil;
    NSCalendar *UTCCalendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDateComponents *UTCComponents = [UTCCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    UTCComponents.timeZone = nil;
    return [UTCComponents isEqual:localComponents];
}

- (BOOL)wmf_UTCDateIsTodayLocal {
    return [self wmf_UTCDateIsSameDateAsLocalDate:[NSDate date]];
}

- (NSDate *)wmf_midnightUTCDate {
    NSCalendar *localCalendar = [NSCalendar wmf_gregorianCalendar];
    NSDateComponents *timelessDateComponents = [localCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    timelessDateComponents.timeZone = nil;
    NSCalendar *UTCCalendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDate *timelessUTCDate = [UTCCalendar dateFromComponents:timelessDateComponents];
    return timelessUTCDate;
}

- (NSDate *)wmf_midnightDate {
    NSCalendar *localCalendar = [NSCalendar wmf_gregorianCalendar];
    NSDateComponents *timelessDateComponents = [localCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    NSDate *timelessDate = [localCalendar dateFromComponents:timelessDateComponents];
    return timelessDate;
}

@end
