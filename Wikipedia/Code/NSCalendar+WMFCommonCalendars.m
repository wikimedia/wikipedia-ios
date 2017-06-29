#import <WMF/NSCalendar+WMFCommonCalendars.h>

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

- (NSDateComponents *)wmf_components:(NSCalendarUnit)unitFlags fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    if (!fromDate || !toDate) {
        return nil;
    }

    NSDateComponents *fromDateComponents = [self components:unitFlags fromDate:fromDate];
    NSDateComponents *toDateComponents = [self components:unitFlags fromDate:toDate];

    if (!fromDateComponents || !toDateComponents) {
        return nil;
    }

    return [self components:unitFlags fromDateComponents:fromDateComponents toDateComponents:toDateComponents options:NSCalendarMatchStrictly];
}

- (NSInteger)wmf_daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    //Don't use wmf_components:fromDate:toDate: above unless it's adapted to work to use different unitFlags for from & to and the output
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

- (NSInteger)wmf_daysFromMonthAndDay:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSDateComponents *fromComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:fromDate];
    NSDateComponents *toComponents = [self components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:toDate];
    NSInteger year = toComponents.year;
    if (toComponents.month == 1 && fromComponents.month == 12) {
        year--;
    }
    fromComponents.year = year;
    fromDate = [self dateFromComponents:fromComponents];
    return [self wmf_daysFromDate:fromDate toDate:toDate];
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

- (NSDate *)wmf_midnightUTCDateFromUTCDate {
    NSCalendar *UTCCalendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDateComponents *timelessDateComponents = [UTCCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    timelessDateComponents.timeZone = nil;
    NSDate *timelessUTCDate = [UTCCalendar dateFromComponents:timelessDateComponents];
    return timelessUTCDate;
}

- (NSDate *)wmf_midnightUTCDateFromLocalDate {
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

- (NSDate *)wmf_midnightLocalDateForEquivalentUTCDate {
    NSCalendar *UTCCalendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDateComponents *timelessDateComponents = [UTCCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    timelessDateComponents.timeZone = nil;
    NSCalendar *localCalendar = [NSCalendar wmf_gregorianCalendar];
    NSDate *timelessLocalDate = [localCalendar dateFromComponents:timelessDateComponents];
    return timelessLocalDate;
}

- (NSDate *)wmf_midnightUTCDateFromLocalDateByAddingDays:(NSInteger)days {
    NSDate *daysAgoDate = [[NSCalendar wmf_gregorianCalendar] dateByAddingUnit:NSCalendarUnitDay value:days toDate:self options:NSCalendarMatchStrictly];
    return [daysAgoDate wmf_midnightUTCDateFromLocalDate];
}

@end
